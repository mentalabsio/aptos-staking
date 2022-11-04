module MentaLabs::reward_vault {
    use std::vector;
    use std::signer;
    use std::error;
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
        start_ts: u64,
        owner: address,
        modifiers: vector<Modifier>,
    }

    /// Stores transmission settings in a resource account, which will also hold the reward coins.
    struct RewardTransmitter<phantom CoinType> has key {
        reserved: u64,
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

    /// Move a new RewardVault to account and create a transmitter
    /// resource for it.
    public entry fun publish_reward_vault<CoinType>(account: &signer, reward_rate: u64) {
        let (resource, sign_capability) = account::create_resource_account(account, b"transmitter");
        let resource_addr = signer::address_of(&resource);

        assert!(!exists<RewardVault<CoinType>>(signer::address_of(account)), error::already_exists(ERESOURCE_ALREADY_EXISTS));
        assert!(!exists<RewardTransmitter<CoinType>>(resource_addr), error::already_exists(ERESOURCE_ALREADY_EXISTS));

        move_to(&resource, RewardTransmitter<CoinType> {
            available: 0,
            reserved: 0,
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
    public entry fun deposit_reward<CoinType>(account: &signer, amount: u64) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(account);
        assert_reward_vault_exists<CoinType>(addr);

        let tx_addr = borrow_global<RewardVault<CoinType>>(addr).tx;

        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(tx_addr);
        tx.available = tx.available + amount;

        let tx_sig = account::create_signer_with_capability(&tx.sign_capability);
        coin::register<CoinType>(&tx_sig);
        coin::transfer<CoinType>(account, tx_addr, amount);
    }

    public entry fun subscribe_with_modifiers<CoinType>(
        account: &signer,
        vault: address,
        modifiers: vector<Modifier>
    ) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(account);
        let  RewardVault { tx, rxs } = borrow_global_mut<RewardVault<CoinType>>(vault);
        let tx = borrow_global_mut<RewardTransmitter<CoinType>>(*tx);

        vector::push_back(rxs, addr);
        tx.num_receivers = vector::length(rxs);

        move_to(account, RewardReceiver<CoinType> {
            start_ts: timestamp::now_seconds(),
            owner: addr,
            modifiers,
        });
    }

    public entry fun subscribe<CoinType>(account: &signer, vault: address) acquires RewardVault, RewardTransmitter {
        subscribe_with_modifiers<CoinType>(account, vault, vector::empty())
    }

    public fun assert_reward_vault_exists<CoinType>(addr: address) {
        assert!(exists<RewardVault<CoinType>>(addr), error::not_found(ERESOURCE_DNE));
    }

    #[test_only]
    fun setup(account: &signer, core_framework: &signer) acquires RewardVault {
        use std::math64;

        timestamp::set_time_has_started_for_testing(core_framework);

        let addr = signer::address_of(account);
        account::create_account_for_test(addr);
        account::create_account_for_test(signer::address_of(core_framework));

        coin::create_fake_money(core_framework, account, 100);
        coin::transfer<coin::FakeMoney>(core_framework, addr, 100);

        assert!(coin::balance<coin::FakeMoney>(addr) == 100, 0);

        let reward_rate = (3 * math64::pow(10, 18)) / 86400;

        publish_reward_vault<coin::FakeMoney>(account, reward_rate);

        let RewardVault { tx, rxs } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        assert!(vector::is_empty(rxs), 0);
        assert!(exists<RewardTransmitter<coin::FakeMoney>>(*tx), 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_deposit_reward(account: signer, core_framework: signer) acquires RewardVault, RewardTransmitter {
        setup(&account, &core_framework);
        deposit_reward<coin::FakeMoney>(&account, 10);

        let addr = signer::address_of(&account);
        let RewardVault { tx, rxs: _ } = borrow_global<RewardVault<coin::FakeMoney>>(addr);

        assert!(coin::balance<coin::FakeMoney>(addr) == 90, 0);
        assert!(coin::balance<coin::FakeMoney>(*tx) == 10, 0);
    }

    #[test(account = @0x111, user1 = @0x112, core_framework = @aptos_framework)]
    public entry fun test_subscribe(account: signer, user1: signer, core_framework: signer) acquires RewardVault, RewardTransmitter {
        let addr = signer::address_of(&account);

        setup(&account, &core_framework);
        deposit_reward<coin::FakeMoney>(&account, 10);

        subscribe<coin::FakeMoney>(&user1, addr);

        let RewardVault { tx, rxs } = borrow_global<RewardVault<coin::FakeMoney>>(addr);
        let num_recv = borrow_global<RewardTransmitter<coin::FakeMoney>>(*tx).num_receivers;

        assert!(vector::length(rxs) == num_recv, 0);
        assert!(exists<RewardReceiver<coin::FakeMoney>>(signer::address_of(&user1)), 0);
    }
}

