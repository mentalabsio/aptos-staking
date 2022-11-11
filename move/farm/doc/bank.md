
<a name="0xcafebabe_bank"></a>

# Module `0xcafebabe::bank`



-  [Struct `Vault`](#0xcafebabe_bank_Vault)
-  [Resource `Bank`](#0xcafebabe_bank_Bank)
-  [Resource `BankResource`](#0xcafebabe_bank_BankResource)
-  [Constants](#@Constants_0)
-  [Function `publish_bank`](#0xcafebabe_bank_publish_bank)
-  [Function `deposit`](#0xcafebabe_bank_deposit)
-  [Function `lock_vault`](#0xcafebabe_bank_lock_vault)
-  [Function `unlock_vault`](#0xcafebabe_bank_unlock_vault)
-  [Function `withdraw`](#0xcafebabe_bank_withdraw)
-  [Function `get_bank_address`](#0xcafebabe_bank_get_bank_address)
-  [Function `assert_vault_exists_at`](#0xcafebabe_bank_assert_vault_exists_at)
-  [Function `bank_exists`](#0xcafebabe_bank_bank_exists)
-  [Function `assert_bank_exists`](#0xcafebabe_bank_assert_bank_exists)
-  [Function `get_user_vault`](#0xcafebabe_bank_get_user_vault)
-  [Function `try_get_vault`](#0xcafebabe_bank_try_get_vault)
-  [Function `has_vault`](#0xcafebabe_bank_has_vault)
-  [Module Specification](#@Module_Specification_1)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x3::token</a>;
</code></pre>



<a name="0xcafebabe_bank_Vault"></a>

## Struct `Vault`



<pre><code><b>struct</b> <a href="bank.md#0xcafebabe_bank_Vault">Vault</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>locked: bool</code>
</dt>
<dd>

</dd>
<dt>
<code>duration: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>start_ts: <a href="_Option">option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_bank_Bank"></a>

## Resource `Bank`

This resource is owned by a resource account, which holds the NFTs
registered in the <code>vaults</code> table.
Each vault has its own state and duration settings.


<pre><code><b>struct</b> <a href="bank.md#0xcafebabe_bank_Bank">Bank</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>vaults: <a href="_Table">table::Table</a>&lt;<a href="_TokenId">token::TokenId</a>, <a href="bank.md#0xcafebabe_bank_Vault">bank::Vault</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>sign_cap: <a href="_SignerCapability">account::SignerCapability</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_bank_BankResource"></a>

## Resource `BankResource`

Resource stored in the user account, that will store the address of
the bank's resource account.


<pre><code><b>struct</b> <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>res: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xcafebabe_bank_EALREADY_EXISTS"></a>

Resource already exists.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_EALREADY_EXISTS">EALREADY_EXISTS</a>: u64 = 0;
</code></pre>



<a name="0xcafebabe_bank_BANK_SEED"></a>

Bank resource address seed.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_BANK_SEED">BANK_SEED</a>: <a href="">vector</a>&lt;u8&gt; = [98, 97, 110, 107];
</code></pre>



<a name="0xcafebabe_bank_ELOCK_NOT_STARTED"></a>

Vault's lock has not started yet.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_ELOCK_NOT_STARTED">ELOCK_NOT_STARTED</a>: u64 = 4;
</code></pre>



<a name="0xcafebabe_bank_ERESOURCE_DNE"></a>

Resource does not exist.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_ERESOURCE_DNE">ERESOURCE_DNE</a>: u64 = 3;
</code></pre>



<a name="0xcafebabe_bank_EVAULT_DNE"></a>

Vault does not exist.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_EVAULT_DNE">EVAULT_DNE</a>: u64 = 2;
</code></pre>



<a name="0xcafebabe_bank_EVAULT_LOCKED"></a>

Vault is locked.


<pre><code><b>const</b> <a href="bank.md#0xcafebabe_bank_EVAULT_LOCKED">EVAULT_LOCKED</a>: u64 = 1;
</code></pre>



<a name="0xcafebabe_bank_publish_bank"></a>

## Function `publish_bank`

Create a new resource account holding a zeroed vault.
Aborts if the bank already exists.


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_publish_bank">publish_bank</a>(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="bank.md#0xcafebabe_bank_publish_bank">publish_bank</a>(<a href="">account</a>: &<a href="">signer</a>) {
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(<a href="_address_of">signer::address_of</a>(<a href="">account</a>)),
        <a href="_already_exists">error::already_exists</a>(<a href="bank.md#0xcafebabe_bank_EALREADY_EXISTS">EALREADY_EXISTS</a>)
    );

    <b>let</b> (resource, sign_cap) =
        <a href="_create_resource_account">account::create_resource_account</a>(<a href="">account</a>, <a href="bank.md#0xcafebabe_bank_BANK_SEED">BANK_SEED</a>);

    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(<a href="_address_of">signer::address_of</a>(&resource)),
        <a href="_already_exists">error::already_exists</a>(<a href="bank.md#0xcafebabe_bank_EALREADY_EXISTS">EALREADY_EXISTS</a>)
    );

    <b>move_to</b>(&resource, <a href="bank.md#0xcafebabe_bank_Bank">Bank</a> {
        vaults: <a href="_new">table::new</a>(),
        sign_cap,
    });

    <b>move_to</b>(<a href="">account</a>, <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
        res: <a href="_address_of">signer::address_of</a>(&resource)
    });
}
</code></pre>



</details>

<a name="0xcafebabe_bank_deposit"></a>

## Function `deposit`

Deposits token into the vault, without locking it.
Aborts if the bank or the vault does not exist.


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_deposit">deposit</a>(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="bank.md#0xcafebabe_bank_deposit">deposit</a>(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>,
    amount: u64
) <b>acquires</b> <a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>let</b> bank_address = <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(&addr);

    <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(&addr);

    <b>let</b> token_vault = <a href="bank.md#0xcafebabe_bank_try_get_vault">try_get_vault</a>(<b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address), token_id);
    <b>let</b> <a href="bank.md#0xcafebabe_bank">bank</a> = <b>borrow_global_mut</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);

    <b>if</b> (<a href="_is_none">option::is_none</a>(&token_vault)) {
        <a href="_add">table::add</a>(&<b>mut</b> <a href="bank.md#0xcafebabe_bank">bank</a>.vaults, token_id, <a href="bank.md#0xcafebabe_bank_Vault">Vault</a> {
            duration: 0,
            locked: <b>false</b>,
            start_ts: <a href="_none">option::none</a>(),
        });
    } <b>else</b> {
        <b>let</b> token_vault = <a href="_borrow">option::borrow</a>(&token_vault);
        <b>assert</b>!(!token_vault.locked, <a href="_invalid_state">error::invalid_state</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_LOCKED">EVAULT_LOCKED</a>));
    };

    <b>let</b> bank_signer = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(
        &<a href="bank.md#0xcafebabe_bank">bank</a>.sign_cap
    );

    <a href="_direct_transfer">token::direct_transfer</a>(<a href="">account</a>, &bank_signer, token_id, amount);
}
</code></pre>



</details>

<details>
<summary>Specification</summary>



<pre><code><b>pragma</b> aborts_if_is_partial;
<b>include</b> <a href="bank.md#0xcafebabe_bank_BankDNEAborts">BankDNEAborts</a>;
<b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
<b>let</b> res = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr).res;
<b>let</b> vaults = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res).vaults;
<b>aborts_if</b> <a href="_spec_contains">table::spec_contains</a>(vaults, token_id)
    && <a href="_spec_get">table::spec_get</a>(vaults, token_id).locked;
</code></pre>




<a name="0xcafebabe_bank_balance_of"></a>


<pre><code><b>fun</b> <a href="bank.md#0xcafebabe_bank_balance_of">balance_of</a>(owner: <b>address</b>, id: <a href="_TokenId">token::TokenId</a>): u64 {
   <b>let</b> token_store = <b>global</b>&lt;<a href="_TokenStore">token::TokenStore</a>&gt;(owner);
   <b>if</b> (<a href="_spec_contains">table::spec_contains</a>(token_store.tokens, id)) {
       <a href="_spec_get">table::spec_get</a>(token_store.tokens, id).amount
   } <b>else</b> {
       0
   }
}
</code></pre>



</details>

<a name="0xcafebabe_bank_lock_vault"></a>

## Function `lock_vault`

Locks a bank's vault.
Aborts if the bank or the vault does not exist or if the vault is locked.


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_lock_vault">lock_vault</a>(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>, duration: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="bank.md#0xcafebabe_bank_lock_vault">lock_vault</a>(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>,
    duration: u64
) <b>acquires</b> <a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>let</b> bank_address = <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(&addr);
    <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(&addr);
    <a href="bank.md#0xcafebabe_bank_assert_vault_exists_at">assert_vault_exists_at</a>(<b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address), token_id);

    <b>let</b> bank_mut = <b>borrow_global_mut</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);
    <b>let</b> vault_mut = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> bank_mut.vaults, token_id);

    <b>assert</b>!(!vault_mut.locked, <a href="_invalid_state">error::invalid_state</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_LOCKED">EVAULT_LOCKED</a>));

    *vault_mut = <a href="bank.md#0xcafebabe_bank_Vault">Vault</a> {
        duration,
        locked: <b>true</b>,
        start_ts: <a href="_some">option::some</a>(<a href="_now_seconds">timestamp::now_seconds</a>()),
    };
}
</code></pre>



</details>

<details>
<summary>Specification</summary>



<pre><code><b>pragma</b> aborts_if_is_partial;
<b>include</b> <a href="bank.md#0xcafebabe_bank_BankDNEAborts">BankDNEAborts</a>;
<b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
<b>let</b> res = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr).res;
<b>let</b> vaults = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res).vaults;
<b>aborts_if</b> !<a href="_spec_contains">table::spec_contains</a>(vaults, token_id);
</code></pre>



</details>

<a name="0xcafebabe_bank_unlock_vault"></a>

## Function `unlock_vault`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="bank.md#0xcafebabe_bank_unlock_vault">unlock_vault</a>(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) entry <b>fun</b> <a href="bank.md#0xcafebabe_bank_unlock_vault">unlock_vault</a>(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>
) <b>acquires</b> <a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>let</b> bank_address = <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(&addr);

    <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(&addr);
    <a href="bank.md#0xcafebabe_bank_assert_vault_exists_at">assert_vault_exists_at</a>(<b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address), token_id);

    <b>let</b> bank_ref = <b>borrow_global_mut</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);
    <b>let</b> vault_ref = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> bank_ref.vaults, token_id);

    <b>assert</b>!(
        <a href="_is_some">option::is_some</a>(&vault_ref.start_ts),
        <a href="_invalid_state">error::invalid_state</a>(<a href="bank.md#0xcafebabe_bank_ELOCK_NOT_STARTED">ELOCK_NOT_STARTED</a>)
    );

    <b>let</b> now_ts = <a href="_now_seconds">timestamp::now_seconds</a>();
    <b>let</b> end_ts = (*<a href="_borrow">option::borrow</a>(&vault_ref.start_ts)) + vault_ref.duration;
    <b>assert</b>!(now_ts &gt;= end_ts, <a href="_invalid_state">error::invalid_state</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_LOCKED">EVAULT_LOCKED</a>));

    *vault_ref = <a href="bank.md#0xcafebabe_bank_Vault">Vault</a> {
        duration: 0,
        locked: <b>false</b>,
        start_ts: <a href="_none">option::none</a>(),
    };
}
</code></pre>



</details>

<details>
<summary>Specification</summary>



<pre><code><b>pragma</b> aborts_if_is_partial;
<b>include</b> <a href="bank.md#0xcafebabe_bank_BankDNEAborts">BankDNEAborts</a>;
<b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
<b>let</b> res = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr).res;
<b>let</b> vaults = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res).vaults;
<b>aborts_if</b> !<a href="_spec_contains">table::spec_contains</a>(vaults, token_id);
<b>aborts_if</b> <a href="_is_none">option::is_none</a>(
    <a href="_spec_get">table::spec_get</a>(vaults, token_id).start_ts
);
</code></pre>



</details>

<a name="0xcafebabe_bank_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="bank.md#0xcafebabe_bank_withdraw">withdraw</a>(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) entry <b>fun</b> <a href="bank.md#0xcafebabe_bank_withdraw">withdraw</a>(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>
) <b>acquires</b> <a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);

    <b>let</b> bank_address = <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(&addr);
    <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(&addr);

    <b>let</b> bank_ref = <b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);
    <a href="bank.md#0xcafebabe_bank_assert_vault_exists_at">assert_vault_exists_at</a>(bank_ref, token_id);

    <b>let</b> vault_ref = <a href="_borrow">table::borrow</a>(&bank_ref.vaults, token_id);
    <b>assert</b>!(!vault_ref.locked, <a href="_invalid_state">error::invalid_state</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_LOCKED">EVAULT_LOCKED</a>));

    <b>let</b> bank_balance = <a href="_balance_of">token::balance_of</a>(bank_address, token_id);
    <b>let</b> bank_signature = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(
        &bank_ref.sign_cap
    );

    <a href="_direct_transfer">token::direct_transfer</a>(&bank_signature, <a href="">account</a>, token_id, bank_balance);

    // Destroy <a href="">token</a> vault.
    <b>let</b> bank_mut = <b>borrow_global_mut</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);
    <a href="_remove">table::remove</a>(&<b>mut</b> bank_mut.vaults, token_id);
}
</code></pre>



</details>

<details>
<summary>Specification</summary>



<pre><code><b>pragma</b> aborts_if_is_partial;
<b>include</b> <a href="bank.md#0xcafebabe_bank_BankDNEAborts">BankDNEAborts</a>;
<b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
<b>let</b> res = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr).res;
<b>let</b> vaults = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res).vaults;
<b>let</b> vault = <a href="_spec_get">table::spec_get</a>(vaults, token_id);
<b>aborts_if</b> <a href="_spec_contains">table::spec_contains</a>(vaults, token_id)
    && vault.locked;
<b>let</b> <b>post</b> vaults_post = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res).vaults;
<b>ensures</b> !<a href="_spec_contains">table::spec_contains</a>(vaults_post, token_id);
</code></pre>



</details>

<a name="0xcafebabe_bank_get_bank_address"></a>

## Function `get_bank_address`

Get a user's bank address.
This function does not check if the bank exists.


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(owner: &<b>address</b>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(owner: &<b>address</b>): <b>address</b> <b>acquires</b> <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a> {
    <b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(*owner).res
}
</code></pre>



</details>

<a name="0xcafebabe_bank_assert_vault_exists_at"></a>

## Function `assert_vault_exists_at`

Asserts that a bank has a vault for a token id.
This function will abort if the vault does not exist.


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_assert_vault_exists_at">assert_vault_exists_at</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">bank::Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_assert_vault_exists_at">assert_vault_exists_at</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>) {
    <b>assert</b>!(<a href="bank.md#0xcafebabe_bank_has_vault">has_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>, token_id), <a href="_not_found">error::not_found</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_DNE">EVAULT_DNE</a>));
}
</code></pre>



</details>

<a name="0xcafebabe_bank_bank_exists"></a>

## Function `bank_exists`



<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_bank_exists">bank_exists</a>(owner: &<b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_bank_exists">bank_exists</a>(owner: &<b>address</b>): bool {
    <b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(*owner)
}
</code></pre>



</details>

<a name="0xcafebabe_bank_assert_bank_exists"></a>

## Function `assert_bank_exists`



<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(owner: &<b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(owner: &<b>address</b>) {
    <b>assert</b>!(<b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(*owner), <a href="_not_found">error::not_found</a>(<a href="bank.md#0xcafebabe_bank_ERESOURCE_DNE">ERESOURCE_DNE</a>));
}
</code></pre>



</details>

<a name="0xcafebabe_bank_get_user_vault"></a>

## Function `get_user_vault`



<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_get_user_vault">get_user_vault</a>(owner: &<b>address</b>, token_id: <a href="_TokenId">token::TokenId</a>): <a href="bank.md#0xcafebabe_bank_Vault">bank::Vault</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bank.md#0xcafebabe_bank_get_user_vault">get_user_vault</a>(
    owner: &<b>address</b>,
    token_id: <a href="_TokenId">token::TokenId</a>
): <a href="bank.md#0xcafebabe_bank_Vault">Vault</a> <b>acquires</b> <a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>, <a href="bank.md#0xcafebabe_bank_Bank">Bank</a> {
    <a href="bank.md#0xcafebabe_bank_assert_bank_exists">assert_bank_exists</a>(owner);
    <b>let</b> bank_address = <a href="bank.md#0xcafebabe_bank_get_bank_address">get_bank_address</a>(owner);
    <b>let</b> <a href="bank.md#0xcafebabe_bank">bank</a> = <b>borrow_global</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(bank_address);
    <b>assert</b>!(<a href="bank.md#0xcafebabe_bank_has_vault">has_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>, token_id), <a href="_not_found">error::not_found</a>(<a href="bank.md#0xcafebabe_bank_EVAULT_DNE">EVAULT_DNE</a>));
    *<a href="_borrow">table::borrow</a>(&<a href="bank.md#0xcafebabe_bank">bank</a>.vaults, token_id)
}
</code></pre>



</details>

<a name="0xcafebabe_bank_try_get_vault"></a>

## Function `try_get_vault`



<pre><code><b>fun</b> <a href="bank.md#0xcafebabe_bank_try_get_vault">try_get_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">bank::Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>): <a href="_Option">option::Option</a>&lt;<a href="bank.md#0xcafebabe_bank_Vault">bank::Vault</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="bank.md#0xcafebabe_bank_try_get_vault">try_get_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>): Option&lt;<a href="bank.md#0xcafebabe_bank_Vault">Vault</a>&gt; {
    <b>if</b> (<a href="bank.md#0xcafebabe_bank_has_vault">has_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>, token_id)) {
        <a href="_some">option::some</a>(*<a href="_borrow">table::borrow</a>(&<a href="bank.md#0xcafebabe_bank">bank</a>.vaults, token_id))
    } <b>else</b> {
        <a href="_none">option::none</a>()
    }
}
</code></pre>



</details>

<a name="0xcafebabe_bank_has_vault"></a>

## Function `has_vault`



<pre><code><b>fun</b> <a href="bank.md#0xcafebabe_bank_has_vault">has_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">bank::Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="bank.md#0xcafebabe_bank_has_vault">has_vault</a>(<a href="bank.md#0xcafebabe_bank">bank</a>: &<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>, token_id: <a href="_TokenId">token::TokenId</a>): bool {
    <a href="_contains">table::contains</a>(&<a href="bank.md#0xcafebabe_bank">bank</a>.vaults, token_id)
}
</code></pre>



</details>

<a name="@Module_Specification_1"></a>

## Module Specification



<pre><code><b>pragma</b> aborts_if_is_partial;
<b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
<b>aborts_if</b> <b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr);
<b>let</b> <b>post</b> res = <b>global</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr).res;
<b>ensures</b> <b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_Bank">Bank</a>&gt;(res);
<b>ensures</b> <b>exists</b>&lt;<a href="bank.md#0xcafebabe_bank_BankResource">BankResource</a>&gt;(addr);
</code></pre>
