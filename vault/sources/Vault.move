module MentaLabs::Vault {
    use std::error;
    use std::signer;
    use aptos_framework::account;
    use aptos_token::token;

    /// Vault:
    /// Locks a fixed amount of tokens for a period of time.
    struct Vault has key {
        locktime: u64,
        locked: bool,
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
            locktime: 0,
            locked: false,
            sign_cap,
        });

        move_to(account, UserVault {
            resource: signer::address_of(&resource),
        });
    }

    spec publish_vault {
        pragma aborts_if_is_partial;
        let addr = signer::address_of(account);
        aborts_if exists<Vault>(addr);
    }

    #[test(account = @0x13)]
    public entry fun starts_vault(account: signer) {
        let addr = signer::address_of(&account);
        aptos_framework::aptos_account::create_account(addr);
        publish_vault(&account);
        assert!(exists<Vault>(addr), error::not_found(ERESOURCE_DNE));
    }
}
