
spec MentaLabs::bank {
    spec schema BankDNEAborts {
        account: signer;

        let addr = signer::address_of(account);
        let res = global<BankResource>(addr).res;
        aborts_if !exists<BankResource>(addr);
        aborts_if !exists<Bank>(res);
    }

    spec publish_vault {
        pragma aborts_if_is_partial;
        let addr = signer::address_of(account);
        aborts_if exists<BankResource>(addr);

        let post res = global<BankResource>(addr).res;
        ensures exists<Bank>(res);
        ensures exists<BankResource>(addr);
    }


    spec deposit {
        pragma aborts_if_is_partial;
        include BankDNEAborts;

        let addr = signer::address_of(account);
        let res = global<BankResource>(addr).res;
        let vaults = global<Bank>(res).vaults;

        aborts_if table::spec_contains(vaults, token_id) 
            && table::spec_get(vaults, token_id).locked;
    }

    spec fun balance_of(owner: address, id: token::TokenId): u64 {
        let token_store = global<token::TokenStore>(owner);
        if (table::spec_contains(token_store.tokens, id)) {
            table::spec_get(token_store.tokens, id).amount
        } else {
            0
        }
    }

    spec lock_vault {
        pragma aborts_if_is_partial;
        include BankDNEAborts;

        let addr = signer::address_of(account);
        let res = global<BankResource>(addr).res;
        let vaults = global<Bank>(res).vaults;

        aborts_if !table::spec_contains(vaults, token_id);
    }

    spec unlock_vault {
        pragma aborts_if_is_partial;
        include BankDNEAborts;

        let addr = signer::address_of(account);
        let res = global<BankResource>(addr).res;
        let vaults = global<Bank>(res).vaults;

        aborts_if !table::spec_contains(vaults, token_id);
        aborts_if option::is_none(
            table::spec_get(vaults, token_id).start_ts
        );
    }

    spec withdraw {
        pragma aborts_if_is_partial;
        include BankDNEAborts;

        let addr = signer::address_of(account);
        let res = global<BankResource>(addr).res;
        let vaults = global<Bank>(res).vaults;

        let vault = table::spec_get(vaults, token_id);

        aborts_if table::spec_contains(vaults, token_id) 
            && vault.locked;

        let post vaults_post = global<Bank>(res).vaults;
        ensures !table::spec_contains(vaults_post, token_id);
   }
}

