module MentaLabs::Vault {
    use std::signer;
    use std::error;

    /// Vault resource:
    /// Locks a fixed amount of tokens for a period of time.
    struct Vault has key {
        balance: u64,
        locktime: u64,
        state: u8,
    }

    /// Vault state variants
    const VSTATE_UNLOCKED: u8 = 0;
    const VSTATE_LOCKED: u8 = 1;

    /// Error codes.
    const EVAULT_EXISTS: u64 = 0;
    const ERESOURCE_DNE: u64 = 0;

    /// Move a zeroed Vault to an account.
    public entry fun publish_vault(account: &signer) {
        assert!(!exists<Vault>(signer::address_of(account)), EVAULT_EXISTS);
        move_to(account, Vault { balance: 0,  locktime: 0, state: VSTATE_UNLOCKED })
    }

    spec publish_vault {
        pragma aborts_if_is_strict;
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
