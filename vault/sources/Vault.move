module MentaLabs::Vault {
    use std::signer;

    /// Vault resource:
    /// - Locks a fixed amount of tokens (T) for a period of time.
    struct Vault has key, drop {
        balance: u64,
        locktime: u64,
    }

    /// Error codes.
    const EVAULT_EXISTS: u64 = 0;

    /// Move a zeroed Vault to an account.
    public entry fun publish_vault(account: &signer) {
        assert!(!exists<Vault>(signer::address_of(account)), EVAULT_EXISTS);
        move_to(account, Vault { balance: 0,  locktime: 0 })
    }

    spec publish_vault {
        pragma aborts_if_is_strict;
        let addr = signer::address_of(account);
        aborts_if exists<Vault>(addr);
    }
}
