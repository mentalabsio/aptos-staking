module MentaLabs::farm {
    use std::string::String;
    use std::vector;
    use std::signer;
    use std::error;
    use std::table::{Self, Table};

    use aptos_token::token;
    use aptos_framework::account;
    use aptos_framework::coin;

    use MentaLabs::reward_vault;
    use MentaLabs::bank;

    /// Farm resource, stored in a resource account.
    /// Generic over R, which is the reward coin type.
    struct Farm<phantom R> has key {
        /// Whitelist of collections that can be staked in the farm (keys),
        /// and the reward rate for each collection (values).
        whitelisted_collections: Table<String, u64>,
        /// Farmers' addresses.
        farmer_handles: vector<address>,
        /// Signature capability.
        sign_cap: account::SignerCapability,
    }

    /// Farmer resource, stored in the user account.
    /// Generic over R, which is the reward coin type.
    /// For now, only stores a table containing the farms and the staked tokens' TokenIds,
    /// but can be extended to store other information.
    struct Farmer<phantom R> has key {
        /// The same farmer can be registered in many farms.
        /// This field is used to keep track of the farms the farmer is registered in (table keys),
        /// and the token ids the farmer has staked in each farm.
        staked: Table<address, vector<token::TokenId>>,
    }

    /// Resource already exists.
    const ERESOURCE_ALREADY_EXISTS: u64 = 0;
    /// Resource does not exist.
    const ERESOURCE_DNE: u64 = 1;
    /// Collection is not whitelisted.
    const ECOLLECTION_NOT_WHITELISTED: u64 = 2;
    /// Collection is already whitelisted.
    const ECOLLECTION_ALREADY_WHITELISTED: u64 = 3;
    /// NFT is already staked
    const EALREADY_STAKED: u64 = 4;
    /// NFT is not staked
    const ENOT_STAKED: u64 = 5;
    /// User is not registered in a farm.
    const ENOT_REGISTERED: u64 = 6;
    /// User is already registered in a farm.
    const EALREADY_REGISTERED: u64 = 7;

    /// Publishes a new farm under a new resource account.
    public entry fun publish_farm<R>(account: &signer) {
        let (farm, sign_cap) = account::create_resource_account(account, b"farm");
        coin::register<R>(&farm);
        reward_vault::publish_reward_vault<R>(&farm, 0);

        let farm_addr = signer::address_of(&farm);
        assert!(
            !exists<Farm<R>>(farm_addr),
            error::already_exists(ERESOURCE_ALREADY_EXISTS)
        );

        move_to(&farm, Farm<R> {
            sign_cap,
            farmer_handles: vector::empty(),
            whitelisted_collections: table::new(),
        });
    }

    /// Add funds to the farm's reward vault.
    public entry fun fund_reward<R>(creator: &signer, amount: u64) acquires Farm {
        let farm_addr = find_farm_address(&signer::address_of(creator));
        coin::transfer<R>(creator, farm_addr, amount);

        let farm = borrow_global<Farm<R>>(farm_addr);
        let farm_signer = account::create_signer_with_capability(&farm.sign_cap);
        reward_vault::fund_vault<R>(&farm_signer, amount);
    }

    /// Withdraw funds from the farm's reward vault.
    public entry fun withdraw_reward<R>(creator: &signer, amount: u64) acquires Farm {
        let farm_addr = find_farm_address(&signer::address_of(creator));
        let farm = borrow_global<Farm<R>>(farm_addr);
        let farm_signer = account::create_signer_with_capability(&farm.sign_cap);
        reward_vault::withdraw_funds<R>(&farm_signer, amount);
        coin::transfer<R>(&farm_signer, signer::address_of(creator), amount);
    }

    /// Whitelist a collection for staking.
    public entry fun add_to_whitelist<R>(
        account: &signer,
        collection_name: String,
        collection_reward_rate: u64,
    ) acquires Farm {
        let farm_addr = find_farm_address(&signer::address_of(account));
        assert!(
            exists<Farm<R>>(farm_addr),
            error::not_found(ERESOURCE_DNE)
        );

        let farm = borrow_global_mut<Farm<R>>(farm_addr);

        assert!(
            !table::contains(&farm.whitelisted_collections, collection_name),
            error::already_exists(ECOLLECTION_ALREADY_WHITELISTED)
        );

        table::add(
            &mut farm.whitelisted_collections,
            collection_name,
            collection_reward_rate
        );
    }

    /// Register a farmer in a farm.
    public entry fun register_farmer<R>(
        account: &signer,
        farm: address
    ) acquires Farm {
        assert!(
            exists<Farm<R>>(farm),
            error::not_found(ERESOURCE_DNE)
        );

        let farmer_addr = signer::address_of(account);

        assert!(
            !is_registered<R>(&farmer_addr, farm),
            error::already_exists(EALREADY_REGISTERED)
        );

        // Allocate farmer resource if it does not exist.
        if (!exists<Farmer<R>>(farmer_addr)) {
            move_to(account, Farmer<R> {
                staked: table::new(),
            });
        };

        // Publish a bank for the farmer.
        if (!bank::bank_exists(&farmer_addr)) {
            bank::publish_bank(account);
        };

        // Register farmer in farm.
        let farm = borrow_global_mut<Farm<R>>(farm);
        vector::push_back(&mut farm.farmer_handles, farmer_addr);
    }

    /// Stake an NFT in a farm.
    public entry fun stake<R>(
        account: &signer,
        token_id: token::TokenId,
        farm: address
    ) acquires Farm, Farmer {
        let (_, collection, _, _) = token::get_token_id_fields(&token_id);
        assert!(is_whitelisted<R>(farm, collection), 1);

        let addr = signer::address_of(account);
        if (!is_registered<R>(&addr, farm)) {
            register_farmer<R>(account, farm);
        };

        let farmer = borrow_global_mut<Farmer<R>>(addr);
        if (!table::contains(&farmer.staked, farm)) {
            table::add(&mut farmer.staked, farm, vector::empty());
        };

        let staked = table::borrow_mut(&mut farmer.staked, farm);
        assert!(
            !vector::contains(staked, &token_id),
            error::invalid_state(EALREADY_STAKED)
        );
        vector::push_back(staked, token_id);

        // Lock the token in a bank
        bank::deposit(account, token_id, 1);

        let collection_modifier = table::borrow(
            &borrow_global<Farm<R>>(farm).whitelisted_collections,
            collection
        );

        if (!reward_vault::is_subscribed<R>(addr, farm)) {
            let modifier = reward_vault::create_sum_modifier(
                *collection_modifier
            );
            reward_vault::subscribe_with_modifier<R>(
                account,
                farm,
                modifier
            );
        } else {
            let identity = account::create_signer_with_capability(
                &borrow_global<Farm<R>>(farm).sign_cap
            );
            reward_vault::increase_modifier_value<R>(
                &identity,
                signer::address_of(account),
                *collection_modifier
            );
        };
    }

    /// Unstake an NFT from a farm.
    public entry fun unstake<R>(
        account: &signer,
        token_id: token::TokenId,
        farm: address
    ) acquires Farm, Farmer {
        let addr = signer::address_of(account);
        assert!(exists<Farmer<R>>(addr), error::not_found(ERESOURCE_DNE));
        assert!(exists<Farm<R>>(farm), error::not_found(ERESOURCE_DNE));
        assert!(is_registered<R>(&addr, farm), error::not_found(ENOT_REGISTERED));

        let farmer = borrow_global_mut<Farmer<R>>(addr);
        let staked = table::borrow_mut(&mut farmer.staked, farm);

        let (exist, index) = vector::index_of(staked, &token_id);
        assert!(exist, error::invalid_state(ENOT_STAKED));
        vector::remove(staked, index);

        // Unlock the token from the bank
        bank::withdraw(account, token_id);

        claim_rewards<R>(account, farm);

        // Unsubscribe from reward vault.
        if (vector::is_empty(staked)) {
            reward_vault::unsubscribe<R>(account, farm);
        } else {
            let (_, collection, _, _) = token::get_token_id_fields(&token_id);
            let collection_modifier = table::borrow(
                &borrow_global<Farm<R>>(farm).whitelisted_collections,
                collection
            );
            let identity = account::create_signer_with_capability(
                &borrow_global<Farm<R>>(farm).sign_cap
            );
            reward_vault::decrease_modifier_value<R>(&identity, addr, *collection_modifier);
        };
    }

    /// Claim rewards from a farm.
    public entry fun claim_rewards<R>(account: &signer, farm: address) acquires Farm {
        let user_addr = signer::address_of(account);
        assert!(exists<Farmer<R>>(user_addr), error::not_found(ERESOURCE_DNE));
        assert!(is_registered<R>(&user_addr, farm), error::invalid_state(ENOT_REGISTERED));
        reward_vault::claim<R>(account, farm);
    }

    public fun find_farm_address(creator: &address): address {
        account::create_resource_address(creator, b"farm")
    }

    public fun get_staked<R>(
        farmer: &address,
        farm: address
    ): vector<token::TokenId> acquires Farmer {
        *table::borrow(&borrow_global<Farmer<R>>(*farmer).staked, farm)
    }

    public fun is_registered<R>(
        farmer: &address,
        farm: address
    ): bool acquires Farm {
        let farm = borrow_global<Farm<R>>(farm);
        vector::contains(&farm.farmer_handles, farmer)
    }

    public fun is_whitelisted<R>(
        farm: address,
        collection_name: String
    ): bool acquires Farm {
        assert!(exists<Farm<R>>(farm), error::not_found(ERESOURCE_DNE));
        let whitelisted_collections =
            &borrow_global<Farm<R>>(farm).whitelisted_collections;
        table::contains(whitelisted_collections, collection_name)
    }

    #[test_only]
    use aptos_framework::coin::FakeMoney;

    #[test_only]
    fun create_collection(creator: &signer) {
        use std::string;

        let collection_name = string::utf8(b"Hello, World");
        let collection_mutation_setting = vector<bool>[false, false, false];

        token::create_collection(
            creator,
            *&collection_name,
            string::utf8(b"Collection: Hello, World"),
            string::utf8(b"https://aptos.dev"),
            10,
            collection_mutation_setting,
        );
    }

    #[test_only]
    public entry fun create_token(
        creator: &signer,
        collection_name: String,
        token_name: String
    ): token::TokenId {
        use std::string;

        let token_mutation_setting = vector<bool>[false, false, false, false, true];
        let default_keys = vector<String>[
            string::utf8(b"attack"),
            string::utf8(b"num_of_use")
        ];
        let default_vals = vector<vector<u8>>[b"10", b"5"];
        let default_types = vector<String>[
            string::utf8(b"integer"),
            string::utf8(b"integer")
        ];
        token::create_token_script(
            creator,
            *&collection_name,
            *&token_name,
            string::utf8(b"Hello, Token"),
            1,
            1,
            string::utf8(b"https://aptos.dev"),
            signer::address_of(creator),
            100,
            0,
            token_mutation_setting,
            default_keys,
            default_vals,
            default_types,
        );
        token::create_token_id_raw(
            signer::address_of(creator),
            *&collection_name,
            *&token_name,
            0
        )
    }

    #[test_only]
    public entry fun setup(
        creator: &signer,
        user: &signer,
        core_framework: &signer
    ): token::TokenId acquires Farm {
        use std::string;
        use aptos_framework::timestamp;

        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);

        aptos_framework::account::create_account_for_test(creator_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(
            signer::address_of(core_framework)
        );

        // Start the core framework's clock
        timestamp::set_time_has_started_for_testing(core_framework);

        // Fund fake money.
        let initial_amount = 1000;
        coin::create_fake_money(core_framework, creator, initial_amount);
        coin::transfer<FakeMoney>(core_framework, creator_addr, initial_amount);
        assert!(coin::balance<FakeMoney>(creator_addr) == initial_amount, 0);

        // Create a new NFT.
        let collection_name = string::utf8(b"Hello, World");
        create_collection(creator);
        let token_id =
            create_token(creator, collection_name, string::utf8(b"Token #1"));
        token::direct_transfer(creator, user, token_id, 1);

        // Publish a new farm under creator account.
        publish_farm<FakeMoney>(creator);
        let farm_addr = find_farm_address(&creator_addr);


        // Whitelist the newly created collection.
        let collection_reward_rate = 1;
        add_to_whitelist<FakeMoney>(creator, collection_name, collection_reward_rate);
        assert!(is_whitelisted<FakeMoney>(farm_addr, collection_name), 1);

        // Fund the farm reward.
        fund_reward<FakeMoney>(creator, initial_amount);

        token_id
    }

    #[test(creator = @0x111, user = @0x222, core_framework = @aptos_framework)]
    public entry fun test_farm_basic(
        creator: &signer,
        user: &signer,
        core_framework: &signer
    ) acquires Farm, Farmer {
        use aptos_framework::timestamp;

        let creator_addr = signer::address_of(creator);
        let user_addr = signer::address_of(user);

        let token_id = setup(creator, user, core_framework);
        let farm_addr = find_farm_address(&creator_addr);

        stake<FakeMoney>(user, token_id, farm_addr);
        assert!(token::balance_of(user_addr, token_id) == 0, 1);

        timestamp::fast_forward_seconds(500);

        unstake<FakeMoney>(user, token_id, farm_addr);
        assert!(token::balance_of(user_addr, token_id) == 1, 1);
        assert!(coin::balance<FakeMoney>(user_addr) == 500 , 1);

        stake<FakeMoney>(user, token_id, farm_addr);
        assert!(token::balance_of(user_addr, token_id) == 0, 1);

        timestamp::fast_forward_seconds(500);

        unstake<FakeMoney>(user, token_id, farm_addr);
        assert!(token::balance_of(user_addr, token_id) == 1, 1);
        assert!(coin::balance<FakeMoney>(user_addr) == 1000 , 1);
    }

    #[test(creator = @0x111, user = @0x222, core_framework = @aptos_framework)]
    public entry fun test_farm_staking(
        creator: signer,
        user: signer,
        core_framework: signer
    ) acquires Farm, Farmer {
        use aptos_framework::timestamp;
        use std::string;

        let token_id = setup(&creator, &user, &core_framework);
        let creator_addr = signer::address_of(&creator);
        let user_addr = signer::address_of(&user);
        let farm_addr = find_farm_address(&creator_addr);

        stake<FakeMoney>(&user, token_id, farm_addr);

        let bank_addr = bank::get_bank_address(&user_addr);

        let staked = get_staked<FakeMoney>(&user_addr, farm_addr);
        bank::assert_bank_exists(&user_addr);
        assert!(reward_vault::is_subscribed<FakeMoney>(user_addr, farm_addr), 1);
        assert!(token::balance_of(bank_addr, token_id) == 1, 1);
        assert!(vector::length(&staked) == 1, 1);

        {
            // Stake another token
            let token_id = create_token(
                &creator,
                string::utf8(b"Hello, World"),
                string::utf8(b"Token #2")
            );
            token::direct_transfer(&creator, &user, token_id, 1);

            stake<FakeMoney>(&user, token_id, farm_addr);

            let staked = get_staked<FakeMoney>(&user_addr, farm_addr);
            assert!(reward_vault::get_modifier<FakeMoney>(user_addr, farm_addr) == 2, 1);
            assert!(token::balance_of(bank_addr, token_id) == 1, 1);
            assert!(vector::length(&staked) == 2, 1);

            timestamp::fast_forward_seconds(250);

            unstake<FakeMoney>(&user, token_id, farm_addr);

            let staked = get_staked<FakeMoney>(&user_addr, farm_addr);
            let coin_balance = coin::balance<FakeMoney>(user_addr);
            assert!(coin_balance == 500, 1);
            assert!(reward_vault::get_modifier<FakeMoney>(user_addr, farm_addr) == 1, 1);
            assert!(token::balance_of(bank_addr, token_id) == 0, 1);
            assert!(token::balance_of(user_addr, token_id) == 1, 1);
            assert!(vector::length(&staked) == 1, 1);
        };

        timestamp::fast_forward_seconds(500);
        unstake<FakeMoney>(&user, token_id, farm_addr);

        let staked = get_staked<FakeMoney>(&user_addr, farm_addr);
        assert!(coin::balance<FakeMoney>(user_addr) == 1000 , 1);
        assert!(!reward_vault::is_subscribed<FakeMoney>(user_addr, farm_addr), 1);
        assert!(token::balance_of(bank_addr, token_id) == 0, 1);
        assert!(token::balance_of(user_addr, token_id) == 1, 1);
        assert!(vector::length(&staked) == 0, 1);
    }
}
