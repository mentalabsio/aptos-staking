module MentaLabs::bank {
    use std::error;
    use std::signer;
    use std::option::{Self, Option};
    use std::table::{Self, Table};
    use aptos_token::token;
    use aptos_framework::account;
    use aptos_framework::timestamp;

    friend MentaLabs::farm;

    struct Vault has store, copy, drop {
        locked: bool,
        duration: u64,
        start_ts: Option<u64>,
    }

    /// This resource is owned by a resource account, which holds the NFTs
    /// registered in the `vaults` table.
    /// Each vault has its own state and duration settings.
    struct Bank has key {
        vaults: Table<token::TokenId, Vault>,
        sign_cap: account::SignerCapability,
    }

    /// Resource stored in the user account, that will store the address of
    /// the bank's resource account.
    struct BankResource has key {
        res: address
    }

    /// Resource already exists.
    const EALREADY_EXISTS: u64 = 0;
    /// Vault is locked.
    const EVAULT_LOCKED: u64 = 1;
    /// Vault does not exist.
    const EVAULT_DNE: u64 = 2;
    /// Resource does not exist.
    const ERESOURCE_DNE: u64 = 3;
    /// Vault's lock has not started yet.
    const ELOCK_NOT_STARTED: u64 = 4;

    /// Bank resource address seed.
    const BANK_SEED: vector<u8> = b"bank";

    // Instruction handlers:
    /// Create a new resource account holding a zeroed vault.
    /// Aborts if the bank already exists.
    public entry fun publish_bank(account: &signer) {
        assert!(
            !exists<BankResource>(signer::address_of(account)),
            error::already_exists(EALREADY_EXISTS)
        );

        let (resource, sign_cap) =
            account::create_resource_account(account, BANK_SEED);

        assert!(
            !exists<Bank>(signer::address_of(&resource)),
            error::already_exists(EALREADY_EXISTS)
        );

        move_to(&resource, Bank {
            vaults: table::new(),
            sign_cap,
        });

        move_to(account, BankResource {
            res: signer::address_of(&resource)
        });
    }

    /// Deposits token into the vault, without locking it.
    /// Aborts if the bank or the vault does not exist.
    public entry fun deposit(
        account: &signer,
        token_id: token::TokenId,
        amount: u64
    ) acquires Bank, BankResource {
        let addr = signer::address_of(account);
        let bank_address = get_bank_address(&addr);

        assert_bank_exists(&addr);

        let token_vault = try_get_vault(borrow_global<Bank>(bank_address), token_id);
        let bank = borrow_global_mut<Bank>(bank_address);

        if (option::is_none(&token_vault)) {
            table::add(&mut bank.vaults, token_id, Vault {
                duration: 0,
                locked: false,
                start_ts: option::none(),
            });
        } else {
            let token_vault = option::borrow(&token_vault);
            assert!(!token_vault.locked, error::invalid_state(EVAULT_LOCKED));
        };

        let bank_signer = account::create_signer_with_capability(
            &bank.sign_cap
        );

        token::direct_transfer(account, &bank_signer, token_id, amount);
    }

    /// Locks a bank's vault.
    /// Aborts if the bank or the vault does not exist or if the vault is locked.
    public entry fun lock_vault(
        account: &signer,
        token_id: token::TokenId,
        duration: u64
    ) acquires Bank, BankResource {
        let addr = signer::address_of(account);
        let bank_address = get_bank_address(&addr);
        assert_bank_exists(&addr);
        assert_vault_exists_at(borrow_global<Bank>(bank_address), token_id);

        let bank_mut = borrow_global_mut<Bank>(bank_address);
        let vault_mut = table::borrow_mut(&mut bank_mut.vaults, token_id);

        assert!(!vault_mut.locked, error::invalid_state(EVAULT_LOCKED));

        *vault_mut = Vault {
            duration,
            locked: true,
            start_ts: option::some(timestamp::now_seconds()),
        };
    }

    public(friend) entry fun unlock_vault(
        account: &signer,
        token_id: token::TokenId
    ) acquires Bank, BankResource {
        let addr = signer::address_of(account);
        let bank_address = get_bank_address(&addr);

        assert_bank_exists(&addr);
        assert_vault_exists_at(borrow_global<Bank>(bank_address), token_id);

        let bank_ref = borrow_global_mut<Bank>(bank_address);
        let vault_ref = table::borrow_mut(&mut bank_ref.vaults, token_id);

        assert!(
            option::is_some(&vault_ref.start_ts),
            error::invalid_state(ELOCK_NOT_STARTED)
        );

        let now_ts = timestamp::now_seconds();
        let end_ts = (*option::borrow(&vault_ref.start_ts)) + vault_ref.duration;
        assert!(now_ts >= end_ts, error::invalid_state(EVAULT_LOCKED));

        *vault_ref = Vault {
            duration: 0,
            locked: false,
            start_ts: option::none(),
        };
    }

    public(friend) entry fun withdraw(
        account: &signer,
        token_id: token::TokenId
    ) acquires Bank, BankResource {
        let addr = signer::address_of(account);

        let bank_address = get_bank_address(&addr);
        assert_bank_exists(&addr);

        let bank_ref = borrow_global<Bank>(bank_address);
        assert_vault_exists_at(bank_ref, token_id);

        let vault_ref = table::borrow(&bank_ref.vaults, token_id);
        assert!(!vault_ref.locked, error::invalid_state(EVAULT_LOCKED));

        let bank_balance = token::balance_of(bank_address, token_id);
        let bank_signature = account::create_signer_with_capability(
            &bank_ref.sign_cap
        );

        token::direct_transfer(&bank_signature, account, token_id, bank_balance);

        // Destroy token vault.
        let bank_mut = borrow_global_mut<Bank>(bank_address);
        table::remove(&mut bank_mut.vaults, token_id);
    }

    // Helper functions
    /// Get a user's bank address.
    /// This function does not check if the bank exists.
    public fun get_bank_address(owner: &address): address acquires BankResource {
        borrow_global<BankResource>(*owner).res
    }

    /// Asserts that a bank has a vault for a token id.
    /// This function will abort if the vault does not exist.
    public fun assert_vault_exists_at(bank: &Bank, token_id: token::TokenId) {
        assert!(has_vault(bank, token_id), error::not_found(EVAULT_DNE));
    }

    public fun bank_exists(owner: &address): bool {
        exists<BankResource>(*owner)
    }

    public fun assert_bank_exists(owner: &address) {
        assert!(exists<BankResource>(*owner), error::not_found(ERESOURCE_DNE));
    }

    public fun get_user_vault(owner: &address, token_id: token::TokenId):
        Vault
        acquires BankResource, Bank
   {
        assert_bank_exists(owner);
        let bank_address = get_bank_address(owner);
        let bank = borrow_global<Bank>(bank_address);
        assert!(has_vault(bank, token_id), error::not_found(EVAULT_DNE));
        *table::borrow(&bank.vaults, token_id)
    }

    fun try_get_vault(bank: &Bank, token_id: token::TokenId): Option<Vault> {
        if (has_vault(bank, token_id)) {
            option::some(*table::borrow(&bank.vaults, token_id))
        } else {
            option::none()
        }
    }

    fun has_vault(bank: &Bank, token_id: token::TokenId): bool {
        table::contains(&bank.vaults, token_id)
    }

    // Tests
    #[test_only]
    public entry fun create_token(creator: &signer, amount: u64):
        token::TokenId
    {
        use std::string::{Self, String};

        let collection_name = string::utf8(b"Hello, World");
        let collection_mutation_setting = vector<bool>[false, false, false];

        token::create_collection(
            creator,
            *&collection_name,
            string::utf8(b"Collection: Hello, World"),
            string::utf8(b"https://aptos.dev"),
            1,
            collection_mutation_setting,
        );

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
            string::utf8(b"Token: Hello, Token"),
            string::utf8(b"Hello, Token"),
            amount,
            amount,
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
            string::utf8(b"Token: Hello, Token"),
            0
        )
    }

    #[test_only]
    public entry fun setup_and_create_token(
        account: &signer,
        core_framework: &signer
    ): token::TokenId {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        timestamp::set_time_has_started_for_testing(core_framework);

        publish_bank(account);

        assert_bank_exists(&addr);

        create_token(account, 1)
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_deposit(
        account: signer,
        core_framework: signer
    ) acquires BankResource, Bank {
        let token_id = setup_and_create_token(&account, &core_framework);

        deposit(&account, token_id, 1);

        let bank_address = get_bank_address(&signer::address_of(&account));
        let user_address = signer::address_of(&account);

        let bank_balance = token::balance_of(bank_address, token_id);
        assert!(bank_balance == 1, 0);

        let user_balance = token::balance_of(user_address, token_id);
        assert!(user_balance == 0, 0);

        let bank_ref = borrow_global<Bank>(bank_address);
        let token_vault = try_get_vault(bank_ref, token_id);
        assert!(option::is_some(&token_vault), 0);
        assert!(!option::borrow(&token_vault).locked, 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_withdraw(
        account: signer,
        core_framework: signer
    ) acquires Bank, BankResource {
        let token_id = setup_and_create_token(&account, &core_framework);
        let lock_duration = 30 * 86400;

        deposit(&account, token_id, 1);
        lock_vault(&account, token_id, lock_duration);

        timestamp::fast_forward_seconds(lock_duration);

        unlock_vault(&account, token_id);
        withdraw(&account, token_id);

        let bank_address = get_bank_address(&signer::address_of(&account));
        let user_address = signer::address_of(&account);

        let bank_balance = token::balance_of(bank_address, token_id);
        assert!(bank_balance == 0, 0);

        let user_balance = token::balance_of(user_address, token_id);
        assert!(user_balance == 1, 0);

        let bank_ref = borrow_global<Bank>(bank_address);
        let token_vault = try_get_vault(bank_ref, token_id);
        assert!(option::is_none(&token_vault), 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_lock(
        account: signer,
        core_framework: signer
    ) acquires Bank, BankResource {
        let token_id = setup_and_create_token(&account, &core_framework);
        deposit(&account, token_id, 1);

        // Lock for 30 days.
        let lock_duration = 30 * 86400;
        lock_vault(&account, token_id, lock_duration);

        let bank_address = get_bank_address(&signer::address_of(&account));
        let bank_ref = borrow_global<Bank>(bank_address);
        let token_vault = try_get_vault(bank_ref, token_id);
        assert!(option::borrow(&token_vault).locked, 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_unlock(
        account: signer,
        core_framework: signer
    ) acquires Bank, BankResource {
        let token_id = setup_and_create_token(&account, &core_framework);
        deposit(&account, token_id, 1);

        // Lock for 30 days.
        let lock_duration = 30 * 86400;
        lock_vault(&account, token_id, lock_duration);

        // Fast forward chain clock
        timestamp::fast_forward_seconds(lock_duration);

        unlock_vault(&account, token_id);

        let addr = signer::address_of(&account);
        let bank_addr = get_bank_address(&addr);
        let bank_ref = borrow_global<Bank>(bank_addr);

        let vault_opt = try_get_vault(bank_ref, token_id);
        let vault = option::extract(&mut vault_opt);

        assert!(vault.locked == false, 0);
        assert!(vault.duration == 0, 0);
        assert!(option::is_none(&vault.start_ts), 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    #[expected_failure(abort_code = 0x30001)]
    public entry fun test_unlock_before_duration_ends(
        account: signer,
        core_framework: signer
    ) acquires Bank, BankResource {
        let token_id = setup_and_create_token(&account, &core_framework);
        deposit(&account, token_id, 1);

        // Lock for 30 days.
        let lock_duration = 30 * 86400;
        lock_vault(&account, token_id, lock_duration);

        // Attempt to unlock it.
        unlock_vault(&account, token_id);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    #[expected_failure(abort_code = 0x30001)]
    public entry fun test_withdraw_when_locked(
        account: signer,
        core_framework: signer
    ) acquires Bank, BankResource {
        let token_id = setup_and_create_token(&account, &core_framework);
        deposit(&account, token_id, 1);
        lock_vault(&account, token_id, 1000);
        withdraw(&account, token_id);
    }
}
