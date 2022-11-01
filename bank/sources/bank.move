module MentaLabs::Bank {
    use std::error;
    use std::signer;
    use std::option::{Self, Option};
    use std::table::{Self, Table};
    use aptos_token::token;
    use aptos_framework::account;
    use aptos_framework::timestamp;

    struct Vault has store, copy, drop {
        locked: bool,
        duration: u64,
        start_ts: Option<u64>,
    }

    /// Vaults a fixed amount of tokens for a period of time.
    struct Bank has key {
        vaults: Table<token::TokenId, Vault>,
        sign_cap: account::SignerCapability,
    }

    /// Error codes.
    const EALREADY_EXISTS: u64 = 0;
    const EVAULT_LOCKED: u64 = 1;
    const EVAULT_DNE: u64 = 2;
    const ERESOURCE_DNE: u64 = 3;

    /// Seeds.
    const BANK_SEED: vector<u8> = b"vault";

    /// Instruction handlers:

    /// Create a new resource account holding a zeroed vault.
    /// Aborts if the bank already exists.
    public entry fun publish_vault(account: &signer) {
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
    }

    /// Deposits token into the vault, without locking it.
    /// Aborts if the bank or the vault does not exist.
    public entry fun deposit(account: &signer, token_id: token::TokenId, amount: u64)
        acquires Bank
    {
        let addr = signer::address_of(account);
        let bank_address = get_bank_address(&addr);
        let token_vault = get_vault(borrow_global<Bank>(bank_address), token_id);
        let bank = borrow_global_mut<Bank>(bank_address);

        if (option::is_none(&token_vault)) {
            table::add(&mut bank.vaults, token_id, Vault {
                duration: 0,
                locked: false,
                start_ts: option::none(),
            });
        } else {
            let token_vault = option::borrow(&token_vault);
            assert!(!token_vault.locked, EVAULT_LOCKED);
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
    ) acquires Bank {
        let addr = signer::address_of(account);
        let bank_address = get_bank_address(&addr);
        let bank_ref = borrow_global<Bank>(bank_address);
        assert!(has_vault(bank_ref, token_id), error::not_found(EVAULT_DNE));

        let bank_mut = borrow_global_mut<Bank>(bank_address);
        let vault_mut = table::borrow_mut(&mut bank_mut.vaults, token_id);

        assert!(!(*vault_mut).locked, EVAULT_LOCKED);

        *vault_mut = Vault {
            duration,
            locked: true,
            start_ts: option::some(timestamp::now_seconds()),
        };
    }

    #[test_only]
    public entry fun create_token(creator: &signer, amount: u64): token::TokenId {
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

        publish_vault(account);

        let bank_addr = get_bank_address(&addr);
        assert!(exists<Bank>(bank_addr), error::not_found(ERESOURCE_DNE));

        create_token(account, 1)
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_deposit(
        account: signer,
        core_framework: signer
    ) acquires Bank {
        let token_id = setup_and_create_token(&account, &core_framework);

        deposit(&account, token_id, 1);

        let bank_address = get_bank_address(&signer::address_of(&account));
        let user_address = signer::address_of(&account);

        let bank_balance = token::balance_of(bank_address, token_id);
        assert!(bank_balance == 1, 0);

        let user_balance = token::balance_of(user_address, token_id);
        assert!(user_balance == 0, 0);

        let bank_ref = borrow_global<Bank>(bank_address);
        let token_vault = get_vault(bank_ref, token_id);
        assert!(option::is_some(&token_vault), 0);
        assert!(!option::borrow(&token_vault).locked, 0);
    }

    #[test(account = @0x111, core_framework = @aptos_framework)]
    public entry fun test_lock(
        account: signer,
        core_framework: signer
    ) acquires Bank {
        let token_id = setup_and_create_token(&account, &core_framework);
        deposit(&account, token_id, 1);

        // Lock for 30 days.
        let lock_duration = 30 * 86400;
        lock_vault(&account, token_id, lock_duration);

        let bank_address = get_bank_address(&signer::address_of(&account));
        let bank_ref = borrow_global<Bank>(bank_address);
        let token_vault = get_vault(bank_ref, token_id);
        assert!(option::borrow(&token_vault).locked, 0);
    }

    /// Helper functions

    /// Get a user's bank address.
    /// This function does not check if the bank exists.
    public fun get_bank_address(owner: &address): address {
        account::create_resource_address(owner, BANK_SEED)
    }

    /// Check if a bank has a vault for a token id.
    public fun has_vault(bank: &Bank, token_id: token::TokenId): bool {
        table::contains(&bank.vaults, token_id)
    }

    /// Get an user's vault for a specific TokenId.
    public fun get_vault(bank: &Bank, token_id: token::TokenId): Option<Vault> {
        if (has_vault(bank, token_id)) {
            option::some(*table::borrow(&bank.vaults, token_id))
        } else {
            option::none()
        }
    }


}
