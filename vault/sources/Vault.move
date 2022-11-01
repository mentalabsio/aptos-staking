module MentaLabs::Vault {
    use std::error;
    use std::signer;
    use std::option::{Self, Option};
    use std::table::{Self, Table};
    use aptos_framework::account;
    use aptos_token::token;

    struct VaultData has store, copy, drop {
        locktime: u64,
        locked: bool,
    }

    /// Vault:
    /// Locks a fixed amount of tokens for a period of time.
    struct Vault has key {
        vaults: Table<token::TokenId, VaultData>,
        sign_cap: account::SignerCapability,
    }

    struct UserVault has key {
        resource: address,
    }

    /// Error codes.
    const EVAULT_EXISTS: u64 = 0;
    const EVAULT_LOCKED: u64 = 1;
    const ERESOURCE_DNE: u64 = 2;

    /// Seeds.
    const VAULT_SEED: vector<u8> = b"vault";

    /// Create a new resource account holding a zeroed vault.
    public entry fun publish_vault(account: &signer) {
        let addr = signer::address_of(account);

        assert!(!exists<UserVault>(addr), EVAULT_EXISTS);

        let (resource, sign_cap) =
            account::create_resource_account(account, VAULT_SEED);

        assert!(
            !exists<Vault>(signer::address_of(&resource)),
            error::already_exists(EVAULT_EXISTS)
        );

        move_to(&resource, Vault {
            vaults: table::new(),
            sign_cap,
        });

        move_to(account, UserVault {
            resource: signer::address_of(&resource),
        });
    }

    /// Get an user's vault for a specific TokenId.
    public fun get_vault(owner: address, token_id: token::TokenId):
        Option<VaultData>
        acquires UserVault, Vault
    {
        assert!(exists<UserVault>(owner), error::not_found(ERESOURCE_DNE));
        let vault_addr = borrow_global<UserVault>(owner).resource;
        assert!(exists<Vault>(vault_addr), error::not_found(ERESOURCE_DNE));

        let vault_acc = borrow_global<Vault>(vault_addr);
        if (table::contains(&vault_acc.vaults, token_id)) {
            option::some(*table::borrow(&vault_acc.vaults, token_id))
        } else {
            option::none()
        }
    }

    public entry fun deposit(account: &signer, token_id: token::TokenId, amount: u64)
        acquires UserVault, Vault
        {
            let addr = signer::address_of(account);
            let token_vault = get_vault(addr, token_id);

            if (option::is_none(&token_vault)) {
                let vault_addr = borrow_global<UserVault>(addr).resource;
                let acc = borrow_global_mut<Vault>(vault_addr);
                table::add(
                    &mut acc.vaults,
                    token_id,
                    VaultData {
                        locktime: 0,
                        locked: false,
                    }
                );
            } else {
                let token_vault = option::borrow(&token_vault);
                assert!(!token_vault.locked, EVAULT_LOCKED);
            };

            let vault_addr = borrow_global<UserVault>(addr).resource;
            assert!(exists<Vault>(vault_addr), error::not_found(ERESOURCE_DNE));
            let vault_acc = borrow_global<Vault>(vault_addr);

            let resource_sig = account::create_signer_with_capability(
                &vault_acc.sign_cap
            );

            token::direct_transfer(account, &resource_sig, token_id, amount);
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
    public entry fun setup_and_create_token(account: &signer): token::TokenId
        acquires UserVault
    {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        publish_vault(account);

        assert!(exists<UserVault>(addr), error::not_found(ERESOURCE_DNE));

        let res_address = borrow_global<UserVault>(addr).resource;
        assert!(exists<Vault>(res_address), error::not_found(ERESOURCE_DNE));

        create_token(account, 1)
    }

    #[test(account = @0x111)]
    public entry fun test_deposit_token(account: signer)
        acquires UserVault, Vault
    {
        let token_id = setup_and_create_token(&account);

        deposit(&account, token_id, 1);

        let vault_address = borrow_global<UserVault>(
            signer::address_of(&account)
        ).resource;

        let vault_balance = token::balance_of(vault_address, token_id);
        assert!(vault_balance == 1, 0);

        let user_balance = token::balance_of(
            signer::address_of(&account),
            token_id
        );
        assert!(user_balance == 0, 0);

        let token_vault = get_vault(signer::address_of(&account), token_id);
        assert!(option::is_some(&token_vault), 0);
        assert!(!option::borrow(&token_vault).locked, 0);
    }

    public entry fun withdraw(_account: &signer, _amount: u64) {
        abort error::not_implemented(0)
    }
}
