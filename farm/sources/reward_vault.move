module MentaLabs::reward_vault {
    use std::vector;
    use std::signer;
    use std::error;
    use std::table::{Self, Table};
    use std::option::{Self, Option};
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    use MentaLabs::queue::{Self, Queue};

    friend MentaLabs::farm;

    /// Modifier kind variants.
    const MODIFIER_SUM: u8 = 0;
    /// Modifier kind variants.
    const MODIFIER_MUL: u8 = 1;

    /// Modifiers for the reward rate, which can be increased by either sum or multiplication of a given value.
    struct Modifier has store, drop {
        kind: u8,
        value: u64,
    }

    struct Vault has store, drop {
        /// Start timestamp.
        start_ts: u64,
        /// Accrued rewards.
        accrued_rewards: u64,
        /// Last update timestamp.
        last_update_ts: u64,
        /// Reward rate modifier.
        modifier: Option<Modifier>,
    }

    /// Stores receiver information in the user account.
    struct RewardReceiver<phantom CoinType> has key {
        vaults: Table<address, Vault>,
    }

    struct Debt has store, copy, drop {
        recv: address,
        amount: u64,
    }

    /// Stores transmission settings in a resource account, which will also hold the reward coins.
    struct RewardTransmitter<phantom CoinType> has key {
        available: u64,
        reward_rate: u64,
        num_receivers: u64,
        debt_queue: Queue<Debt>,
        sign_capability: account::SignerCapability,
    }

    /// Single transmitter, multiple receivers.
    struct RewardVault<phantom CoinType> has key {
        /// Vault transmitter handle.
        tx: address,
        /// Vault receiver handles.
        rxs: vector<address>,
    }

    /// Resource already exists.
    const ERESOURCE_ALREADY_EXISTS: u64 = 0;
    /// Resource does not exist.
    const ERESOURCE_DNE: u64 = 1;
    /// Insufficient rewards in vault.
    const EINSUFFICIENT_REWARDS: u64 = 2;

    /// Move a new RewardVault to account and create a transmitter
    /// resource for it.
    public entry fun publish_reward_vault<CoinType>(
        account: &signer,
        reward_rate: u64
    ) {
        let (resource, sign_capability) =
            account::create_resource_account(account, b"transmitter");
        let resource_addr = signer::address_of(&resource);

        assert!(
            !exists<RewardVault<CoinType>>(signer::address_of(account)),
            error::already_exists(ERESOURCE_ALREADY_EXISTS)
        );
        assert!(
            !exists<RewardTransmitter<CoinType>>(resource_addr),
            error::already_exists(ERESOURCE_ALREADY_EXISTS)
        );

        coin::register<CoinType>(&resource);

        move_to(&resource, RewardTransmitter<CoinType> {
            available: 0,
            num_receivers: 0,
            reward_rate,
            debt_queue: queue::new(),
            sign_capability,
        });

        move_to(account, RewardVault<CoinType> {
            tx: resource_addr,
            rxs: vector::empty()
        });
    }

    /// Transfer coins to reward transmitter.
    /// Must be done by the creator.
    public entry fun fund_vault<CoinType>(
        account: &signer,
        amount: u64
    ) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(account);
        assert_reward_vault_exists<CoinType>(addr);

        let tx_addr = borrow_global<RewardVault<CoinType>>(addr).tx;
        coin::transfer<CoinType>(account, tx_addr, amount);

        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(tx_addr);
        tx.available = tx.available + amount;

        let tx_signature = account::create_signer_with_capability(&tx.sign_capability);

        if (!queue::is_empty(&tx.debt_queue)) {
            // Pay accrued debts.
            pay_debts<CoinType>(&tx_signature);
        }
    }

    fun pay_debts<CoinType>(tx: &signer) acquires RewardTransmitter {
        let addr = signer::address_of(tx);
        let transmitter = borrow_global_mut<RewardTransmitter<CoinType>>(addr);
        let debt_queue = &mut transmitter.debt_queue;

        let first = queue::pop_front(debt_queue);
        while (option::is_some(&first)) {
            let debt = option::extract(&mut first);
            let available = transmitter.available;

            if (debt.amount <= available) {
                coin::transfer<CoinType>(tx, debt.recv, debt.amount);
                transmitter.available = transmitter.available - debt.amount;
            } else {
                let amount = debt.amount - available;
                coin::transfer<CoinType>(tx, debt.recv, amount);
                debt.amount = debt.amount - amount;
                queue::push_back(debt_queue, debt);
                transmitter.available = 0;
                break
            };

            first = queue::pop_front(debt_queue);
        };
    }

    /// Withdraw funds from reward transmitter.
    /// Must be done by the creator.
    public entry fun withdraw_funds<CoinType>(
        account: &signer,
        amount: u64
    ) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(account);
        assert_reward_vault_exists<CoinType>(addr);

        let tx_addr = borrow_global<RewardVault<CoinType>>(addr).tx;
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(tx_addr);
        assert!(tx.available >= amount, error::invalid_argument(EINSUFFICIENT_REWARDS));

        tx.available = tx.available - amount;
        let tx_signature = account::create_signer_with_capability(
            &tx.sign_capability
        );
        coin::transfer<CoinType>(&tx_signature, addr, amount);
    }

    public entry fun subscribe<CoinType>(
        account: &signer,
        vault: address
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        internal_subscribe<CoinType>(account, vault, option::none());
    }

    public entry fun subscribe_with_modifier<CoinType>(
        account: &signer,
        vault: address,
        modifier: Modifier
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        internal_subscribe<CoinType>(account, vault, option::some(modifier));
    }

    fun internal_subscribe<CoinType>(
        account: &signer,
        vault: address,
        modifier: Option<Modifier>
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(account);
        let  RewardVault { tx, rxs } =
            borrow_global_mut<RewardVault<CoinType>>(vault);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(*tx);

        vector::push_back(rxs, addr);
        tx.num_receivers = tx.num_receivers + 1;

        if (!coin::is_account_registered<CoinType>(addr)) {
            coin::register<CoinType>(account);
        };

        let now_ts = timestamp::now_seconds();

        if (!exists<RewardReceiver<CoinType>>(addr)) {
            let vaults = table::new();
            table::add(&mut vaults, vault, Vault {
                start_ts: now_ts,
                accrued_rewards: 0,
                last_update_ts: now_ts,
                modifier,
            });
            move_to(account, RewardReceiver<CoinType> { vaults });
        } else {
            let recv = borrow_global_mut<RewardReceiver<CoinType>>(addr);
            assert!(
                !table::contains(&recv.vaults, vault),
                error::already_exists(ERESOURCE_ALREADY_EXISTS)
            );
            table::add(&mut recv.vaults, vault, Vault {
                start_ts: now_ts,
                accrued_rewards: 0,
                last_update_ts: now_ts,
                modifier,
            });
        };

    }

    public entry fun unsubscribe<CoinType>(
        account: &signer,
        vault: address
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        // claim accrued rewards.
        claim<CoinType>(account, vault);

        let RewardVault { tx, rxs } =
            borrow_global_mut<RewardVault<CoinType>>(vault);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(*tx);

        let addr = signer::address_of(account);
        let (exist, i) = vector::index_of(rxs, &addr);
        assert!(exist, error::not_found(ERESOURCE_DNE));

        vector::remove(rxs, i);
        tx.num_receivers = tx.num_receivers - 1;

        let recv = borrow_global_mut<RewardReceiver<CoinType>>(addr);
        table::remove(&mut recv.vaults, vault);
    }

    public entry fun claim<CoinType>(
        account: &signer,
        vault: address
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(account);

        assert!(
            exists<RewardReceiver<CoinType>>(addr),
            error::not_found(ERESOURCE_DNE)
        );

        assert!(is_subscribed<CoinType>(addr, vault), error::not_found(ERESOURCE_DNE));

        update_accrued_rewards<CoinType>(addr, vault, timestamp::now_seconds());

        let recv = borrow_global_mut<RewardReceiver<CoinType>>(addr);
        let vault_ref = table::borrow_mut(&mut recv.vaults, vault);
        let reward_vault = borrow_global<RewardVault<CoinType>>(vault);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(reward_vault.tx);
        let reward = vault_ref.accrued_rewards;

        let tx_sig =
            account::create_signer_with_capability(&tx.sign_capability);

        assert!(
            coin::is_account_registered<CoinType>(signer::address_of(&tx_sig)),
            error::invalid_state(EINSUFFICIENT_REWARDS)
        );

        // Add user to debt queue if there is not enough reward available
        if (reward > tx.available) {
            let debt_amount = reward - tx.available;
            queue::push_back(&mut tx.debt_queue, Debt { recv: addr, amount: debt_amount });
            reward = tx.available;
       };

        if (reward > 0) {
            coin::transfer<CoinType>(&tx_sig, addr, reward);
        };

        tx.available = tx.available - reward;
        vault_ref.accrued_rewards = 0;
    }

    public(friend) fun update_accrued_rewards<CoinType>(
        recv_addr: address,
        vault: address,
        now: u64
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let recv = borrow_global_mut<RewardReceiver<CoinType>>(recv_addr);
        assert_reward_vault_exists<CoinType>(vault);

        let transmitter_addr = borrow_global<RewardVault<CoinType>>(vault).tx;
        let transmitter = borrow_global<RewardTransmitter<CoinType>>(transmitter_addr);

        let vault = table::borrow_mut(&mut recv.vaults, vault);

        let elapsed = now - vault.last_update_ts;
        let reward_rate = if (option::is_some(&vault.modifier)) {
            let modifier = option::borrow(&vault.modifier);
            if (modifier.kind == MODIFIER_SUM) {
                transmitter.reward_rate + modifier.value
            } else {
                transmitter.reward_rate * modifier.value
            }
        } else {
            transmitter.reward_rate
        };
        vault.accrued_rewards = vault.accrued_rewards + reward_rate * elapsed;
        vault.last_update_ts = now;
    }


    public(friend) fun increase_modifier_value<CoinType>(
        vault: &signer,
        account: address,
        lhs: u64
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let vault_addr = signer::address_of(vault);
        let recv = borrow_global<RewardReceiver<CoinType>>(account);
        assert!(table::contains(&recv.vaults, vault_addr), error::not_found(ERESOURCE_DNE));

        let vault_ref = table::borrow(&recv.vaults, vault_addr);
        let Modifier { kind, value } = option::borrow_with_default(&vault_ref.modifier, &Modifier { value: 1, kind: MODIFIER_MUL });
        update_modifier<CoinType>(vault, account, option::some(Modifier { kind: *kind, value: *value + lhs } ));
    }

    public(friend) fun decrease_modifier_value<CoinType>(
        vault: &signer,
        account: address,
        lhs: u64
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let vault_addr = signer::address_of(vault);
        let recv = borrow_global<RewardReceiver<CoinType>>(account);
        assert!(table::contains(&recv.vaults, vault_addr), error::not_found(ERESOURCE_DNE));

        let vault_ref = table::borrow(&recv.vaults, vault_addr);
        let Modifier { kind, value } = option::borrow_with_default(&vault_ref.modifier, &Modifier { value: 1, kind: MODIFIER_MUL });
        update_modifier<CoinType>(vault, account, option::some(Modifier { kind: *kind, value: *value - lhs } ));
    }

    public(friend) fun update_modifier<CoinType>(
        vault: &signer,
        account: address,
        modifier: Option<Modifier>
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let vault_addr = signer::address_of(vault);

        update_accrued_rewards<CoinType>(account, vault_addr, timestamp::now_seconds());

        let receiver = borrow_global_mut<RewardReceiver<CoinType>>(account);
        assert!(
            table::contains(&receiver.vaults, vault_addr),
            error::not_found(ERESOURCE_DNE)
        );
        let vault_ref = table::borrow_mut(&mut receiver.vaults, vault_addr);
        vault_ref.modifier = modifier;
    }

    public(friend) fun create_sum_modifier(value: u64): Modifier {
        Modifier { kind: MODIFIER_SUM, value }
    }

    public(friend) fun create_mul_modifier(value: u64): Modifier {
        Modifier { kind: MODIFIER_MUL, value }
    }

    public(friend) fun get_modifier<CoinType>(
        account: address,
        vault: address
    ): u64 acquires RewardReceiver {
        assert!(exists<RewardReceiver<CoinType>>(account), error::not_found(ERESOURCE_DNE));
        assert!(exists<RewardVault<CoinType>>(vault), error::not_found(ERESOURCE_DNE));

        let recv = borrow_global<RewardReceiver<CoinType>>(account);
        assert!(table::contains(&recv.vaults, vault), error::not_found(ERESOURCE_DNE));

        let vault = table::borrow(&recv.vaults, vault);
        let Modifier { kind: _, value } = option::borrow_with_default(
            &vault.modifier,
            &Modifier { value: 0, kind: MODIFIER_MUL }
        );
        *value
    }

    public fun get_accrued_rewards<CoinType>(
        account: address,
        vault: address
    ): u64 acquires RewardVault, RewardReceiver, RewardTransmitter {
        assert!(exists<RewardReceiver<CoinType>>(account), error::not_found(ERESOURCE_DNE));
        assert!(exists<RewardVault<CoinType>>(vault), error::not_found(ERESOURCE_DNE));
        assert!(is_subscribed<CoinType>(account, vault), error::not_found(ERESOURCE_DNE));

        update_accrued_rewards<CoinType>(account, vault, timestamp::now_seconds());

        let recv = borrow_global<RewardReceiver<CoinType>>(account);
        assert!(table::contains(&recv.vaults, vault), error::not_found(ERESOURCE_DNE));

        let vault = table::borrow(&recv.vaults, vault);
        vault.accrued_rewards
    }

    public fun is_subscribed<CoinType>(
        account: address,
        vault: address
    ): bool acquires RewardVault {
        if (!exists<RewardVault<CoinType>>(vault)) {
            return false
        };
        let RewardVault { rxs, tx: _ } = borrow_global<RewardVault<CoinType>>(vault);
        vector::contains(rxs, &account)
    }

    public fun assert_reward_vault_exists<CoinType>(addr: address) {
        assert!(
            exists<RewardVault<CoinType>>(addr),
            error::not_found(ERESOURCE_DNE)
        );
    }

    #[test_only]
    fun setup(
        account: &signer,
        core_framework: &signer
    ) acquires RewardVault, RewardTransmitter {
        use std::math64;
        timestamp::set_time_has_started_for_testing(core_framework);

        let addr = signer::address_of(account);
        account::create_account_for_test(addr);
        account::create_account_for_test(signer::address_of(core_framework));

        let initial_amount = (10 * math64::pow(10, 18));
        coin::create_fake_money(core_framework, account, initial_amount);
        coin::transfer<coin::FakeMoney>(core_framework, addr, initial_amount);
        assert!(coin::balance<coin::FakeMoney>(addr) == initial_amount, 0);

        let reward_rate = (1 * math64::pow(10, 18)) / 86400;
        publish_reward_vault<coin::FakeMoney>(account, reward_rate);

        let RewardVault { tx, rxs } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        assert!(vector::is_empty(rxs), 0);
        assert!(exists<RewardTransmitter<coin::FakeMoney>>(*tx), 0);

        fund_vault<coin::FakeMoney>(account, initial_amount);

        let addr = signer::address_of(account);
        let RewardVault { tx, rxs: _ } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        assert!(coin::balance<coin::FakeMoney>(addr) == 0, 0);
        assert!(coin::balance<coin::FakeMoney>(*tx) == initial_amount, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_subscribe(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        account::create_account_for_test(signer::address_of(&user1));
        let addr = signer::address_of(&account);
        setup(&account, &core_framework);
        subscribe<coin::FakeMoney>(&user1, addr);

        let RewardVault { tx, rxs } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        let num_recv = borrow_global<RewardTransmitter<coin::FakeMoney>>(*tx).num_receivers;
        assert!(vector::length(rxs) == num_recv, 0);
        assert!(exists<RewardReceiver<coin::FakeMoney>>(signer::address_of(&user1)), 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_unsubscribe(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(&account);
        let user_addr = signer::address_of(&user1);

        account::create_account_for_test(user_addr);
        setup(&account, &core_framework);
        subscribe<coin::FakeMoney>(&user1, addr);

        timestamp::fast_forward_seconds(86400);
        unsubscribe<coin::FakeMoney>(&user1, addr);

        // assert!(!exists<RewardReceiver<coin::FakeMoney>>(user_addr), 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_claim(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe<coin::FakeMoney>(&user1, addr);
        timestamp::fast_forward_seconds(86400);
        claim<coin::FakeMoney>(&user1, addr);

        let tx = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let reward_rate = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx).reward_rate;
        let expected = reward_rate * 86400;
        let balance = coin::balance<coin::FakeMoney>(user1_addr);
        assert!(balance == expected, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_with_modifier(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe_with_modifier<coin::FakeMoney>(
            &user1,
            addr,
            create_mul_modifier(2)
        );
        timestamp::fast_forward_seconds(86400);
        claim<coin::FakeMoney>(&user1, addr);

        let tx = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let reward_rate = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx).reward_rate;
        let expected = (reward_rate * 2) * 86400;
        let balance = coin::balance<coin::FakeMoney>(user1_addr);
        assert!(balance == expected, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_update_modifier(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe_with_modifier<coin::FakeMoney>(
            &user1,
            addr,
            create_mul_modifier(2)
        );
        timestamp::fast_forward_seconds(86400);

        let tx = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let reward_rate = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx).reward_rate;
        let expected = (reward_rate * 2) * 86400;
        let accrued_rewards = get_accrued_rewards<coin::FakeMoney>(user1_addr, addr);
        assert!(accrued_rewards == expected, 0);

        claim<coin::FakeMoney>(&user1, addr);
        let balance = coin::balance<coin::FakeMoney>(user1_addr);
        assert!(balance == expected, 0);

        let new_modifier = create_mul_modifier(3);
        update_modifier<coin::FakeMoney>(
            &account,
            user1_addr,
            option::some(new_modifier)
        );
        timestamp::fast_forward_seconds(86400);
        claim<coin::FakeMoney>(&user1, addr);

        let expected = (reward_rate * 3) * 86400;
        let balance2 = coin::balance<coin::FakeMoney>(user1_addr);
        assert!(balance2 == expected + balance, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_debt(
        account: signer,
        user1: signer,
        core_framework: signer
    ) acquires RewardVault, RewardReceiver, RewardTransmitter {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe_with_modifier<coin::FakeMoney>(
            &user1,
            addr,
            create_mul_modifier(2)
        );

        // there is not enough rewards for 6 days of subscription
        timestamp::fast_forward_seconds(6 * 86400);

        let tx_addr = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let available = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx_addr).available;

        claim<coin::FakeMoney>(&user1, addr);

        // expect the transmitter to pay what it cans and crate a debt for the rest.
        let balance = coin::balance<coin::FakeMoney>(user1_addr);
        assert!(balance == available, 0);

        // check debt queue
        let transmitter = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx_addr);
        let debt = queue::peek(&transmitter.debt_queue);
        let expected = (transmitter.reward_rate * 2) * (6 * 86400) - available;
        assert!(option::is_some(&debt), 0);

        let debt = option::borrow(&debt);
        assert!(debt.recv == user1_addr, 0);
        assert!(debt.amount == expected, 0);

    }
}

