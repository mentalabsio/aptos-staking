module MentaLabs::reward_vault {
    use std::vector;
    use std::signer;
    use std::error;
    use std::option::{Self, Option};
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    /// Modifier kind variants.
    const MODIFIER_SUM: u8 = 0;
    /// Modifier kind variants.
    const MODIFIER_MUL: u8 = 1;

    /// Modifiers for the reward rate, which can be increased by either sum or multiplication of a given value.
    struct Modifier has store, drop {
        kind: u8,
        value: u64,
    }

    /// Stores receiver information in the user account.
    struct RewardReceiver<phantom CoinType> has key {
        /// Start timestamp.
        start_ts: u64,
        /// Owner address.
        owner: address,
        /// Vault handle.
        vh: address,
        /// Reward rate modifier.
        modifier: Option<Modifier>,
    }

    /// Stores transmission settings in a resource account, which will also hold the reward coins.
    struct RewardTransmitter<phantom CoinType> has key {
        available: u64,
        reward_rate: u64,
        num_receivers: u64,
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

        move_to(&resource, RewardTransmitter<CoinType> {
            available: 0,
            num_receivers: 0,
            reward_rate,
            sign_capability,
        });

        move_to(account, RewardVault<CoinType> {
            tx: resource_addr,
            rxs: vector::empty()
        });
    }

    /// Transfer coins to reward transmitter.
    /// Must be done by the creator.
    public entry fun fund_vault<CoinType>(account: &signer, amount: u64)
        acquires RewardVault, RewardTransmitter
    {
        let addr = signer::address_of(account);
        assert_reward_vault_exists<CoinType>(addr);

        let tx_addr = borrow_global<RewardVault<CoinType>>(addr).tx;

        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(tx_addr);
        tx.available = tx.available + amount;

        let tx_sig =
            account::create_signer_with_capability(&tx.sign_capability);
        coin::register<CoinType>(&tx_sig);
        coin::transfer<CoinType>(account, tx_addr, amount);
    }

    public entry fun subscribe<CoinType>(account: &signer, vault: address)
        acquires RewardVault, RewardTransmitter
    {
        subscribe_with_modifier<CoinType>(account, vault, option::none());
    }

    public entry fun subscribe_with_modifier<CoinType>(
        account: &signer,
        vault: address,
        modifier: Option<Modifier>
    ) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(account);
        let  RewardVault { tx, rxs } =
            borrow_global_mut<RewardVault<CoinType>>(vault);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(*tx);

        vector::push_back(rxs, addr);
        tx.num_receivers = vector::length(rxs);

        move_to(account, RewardReceiver<CoinType> {
            modifier,
            vh: vault,
            owner: addr,
            start_ts: timestamp::now_seconds(),
        });
    }

    public entry fun claim<CoinType>(account: &signer)
        acquires RewardVault, RewardReceiver, RewardTransmitter
    {
        let addr = signer::address_of(account);
        assert!(
            exists<RewardReceiver<CoinType>>(addr),
            error::not_found(ERESOURCE_DNE)
        );

        let recv = borrow_global<RewardReceiver<CoinType>>(addr);
        assert_reward_vault_exists<CoinType>(recv.vh);

        let vault = borrow_global<RewardVault<CoinType>>(recv.vh);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(vault.tx);
        let reward_rate = tx.reward_rate;

        let now_ts = timestamp::now_seconds();
        let elapsed_seconds = now_ts - recv.start_ts;

        if (option::is_some(&recv.modifier)) {
            let Modifier { kind, value } = option::borrow(&recv.modifier);
            if (*kind == MODIFIER_SUM) {
                reward_rate = reward_rate + *value;
            } else if (*kind == MODIFIER_MUL) {
                reward_rate = reward_rate * *value;
            };
        };

        let reward = reward_rate * elapsed_seconds;

        assert!(reward <= tx.available, error::invalid_state(EINSUFFICIENT_REWARDS));

        let tx_sig =
            account::create_signer_with_capability(&tx.sign_capability);
        coin::register<CoinType>(account);
        coin::transfer<CoinType>(&tx_sig, addr, reward);
    }

    public fun assert_reward_vault_exists<CoinType>(addr: address) {
        assert!(
            exists<RewardVault<CoinType>>(addr),
            error::not_found(ERESOURCE_DNE)
        );
    }

    #[test_only]
    fun setup(account: &signer, core_framework: &signer) acquires RewardVault, RewardTransmitter {
        use std::math64;
        timestamp::set_time_has_started_for_testing(core_framework);

        let addr = signer::address_of(account);
        account::create_account_for_test(addr);
        account::create_account_for_test(signer::address_of(core_framework));

        let initial_amount = (10 * math64::pow(10, 18));
        coin::create_fake_money(core_framework, account, initial_amount);
        coin::transfer<coin::FakeMoney>(core_framework, addr, initial_amount);
        assert!(coin::balance<coin::FakeMoney>(addr) == initial_amount, 0);

        let reward_rate = (3 * math64::pow(10, 18)) / 86400;
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
    public entry fun test_subscribe(account: signer, user1: signer, core_framework: signer) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(&account);
        setup(&account, &core_framework);
        subscribe<coin::FakeMoney>(&user1, addr);

        let RewardVault { tx, rxs } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        let num_recv = borrow_global<RewardTransmitter<coin::FakeMoney>>(*tx).num_receivers;

        assert!(vector::length(rxs) == num_recv, 0);
        assert!(exists<RewardReceiver<coin::FakeMoney>>(signer::address_of(&user1)), 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_claim(account: signer, user1: signer, core_framework: signer)
        acquires RewardVault, RewardReceiver, RewardTransmitter
    {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe<coin::FakeMoney>(&user1, addr);

        timestamp::fast_forward_seconds(86400);
        claim<coin::FakeMoney>(&user1);

        let tx = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let reward_rate = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx).reward_rate;

        let expected = reward_rate * 86400;
        let balance = coin::balance<coin::FakeMoney>(user1_addr);

        assert!(balance == expected, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_with_modifier(account: signer, user1: signer, core_framework: signer)
        acquires RewardVault, RewardReceiver, RewardTransmitter
    {
        let addr = signer::address_of(&account);
        let user1_addr = signer::address_of(&user1);

        account::create_account_for_test(user1_addr);
        setup(&account, &core_framework);
        subscribe_with_modifier<coin::FakeMoney>(
            &user1,
            addr,
            option::some(Modifier { kind: MODIFIER_MUL, value: 2 })
        );

        timestamp::fast_forward_seconds(86400);
        claim<coin::FakeMoney>(&user1);

        let tx = borrow_global<RewardVault<coin::FakeMoney>>(addr).tx;
        let reward_rate = borrow_global<RewardTransmitter<coin::FakeMoney>>(tx).reward_rate;

        let expected = (reward_rate * 2) * 86400;
        let balance = coin::balance<coin::FakeMoney>(user1_addr);

        assert!(balance == expected, 0);
    }
}

