
<a name="0xcafebabe_reward_vault"></a>

# Module `0xcafebabe::reward_vault`



-  [Struct `Modifier`](#0xcafebabe_reward_vault_Modifier)
-  [Struct `Vault`](#0xcafebabe_reward_vault_Vault)
-  [Resource `RewardReceiver`](#0xcafebabe_reward_vault_RewardReceiver)
-  [Struct `Debt`](#0xcafebabe_reward_vault_Debt)
-  [Resource `RewardTransmitter`](#0xcafebabe_reward_vault_RewardTransmitter)
-  [Resource `RewardVault`](#0xcafebabe_reward_vault_RewardVault)
-  [Constants](#@Constants_0)
-  [Function `publish_reward_vault`](#0xcafebabe_reward_vault_publish_reward_vault)
-  [Function `fund_vault`](#0xcafebabe_reward_vault_fund_vault)
-  [Function `pay_debts`](#0xcafebabe_reward_vault_pay_debts)
-  [Function `withdraw_funds`](#0xcafebabe_reward_vault_withdraw_funds)
-  [Function `subscribe`](#0xcafebabe_reward_vault_subscribe)
-  [Function `subscribe_with_modifier`](#0xcafebabe_reward_vault_subscribe_with_modifier)
-  [Function `internal_subscribe`](#0xcafebabe_reward_vault_internal_subscribe)
-  [Function `unsubscribe`](#0xcafebabe_reward_vault_unsubscribe)
-  [Function `claim`](#0xcafebabe_reward_vault_claim)
-  [Function `update_accrued_rewards`](#0xcafebabe_reward_vault_update_accrued_rewards)
-  [Function `increase_modifier_value`](#0xcafebabe_reward_vault_increase_modifier_value)
-  [Function `decrease_modifier_value`](#0xcafebabe_reward_vault_decrease_modifier_value)
-  [Function `update_modifier`](#0xcafebabe_reward_vault_update_modifier)
-  [Function `create_sum_modifier`](#0xcafebabe_reward_vault_create_sum_modifier)
-  [Function `create_mul_modifier`](#0xcafebabe_reward_vault_create_mul_modifier)
-  [Function `get_modifier`](#0xcafebabe_reward_vault_get_modifier)
-  [Function `get_accrued_rewards`](#0xcafebabe_reward_vault_get_accrued_rewards)
-  [Function `is_subscribed`](#0xcafebabe_reward_vault_is_subscribed)
-  [Function `assert_reward_vault_exists`](#0xcafebabe_reward_vault_assert_reward_vault_exists)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0xcafebabe::queue</a>;
</code></pre>



<a name="0xcafebabe_reward_vault_Modifier"></a>

## Struct `Modifier`

Modifiers for the reward rate, which can be increased by either sum or multiplication of a given value.


<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>kind: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>value: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_reward_vault_Vault"></a>

## Struct `Vault`



<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Vault">Vault</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>start_ts: u64</code>
</dt>
<dd>
 Start timestamp.
</dd>
<dt>
<code>accrued_rewards: u64</code>
</dt>
<dd>
 Accrued rewards.
</dd>
<dt>
<code>last_update_ts: u64</code>
</dt>
<dd>
 Last update timestamp.
</dd>
<dt>
<code>modifier: <a href="_Option">option::Option</a>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>&gt;</code>
</dt>
<dd>
 Reward rate modifier.
</dd>
</dl>


</details>

<a name="0xcafebabe_reward_vault_RewardReceiver"></a>

## Resource `RewardReceiver`

Stores receiver information in the user account.


<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>vaults: <a href="_Table">table::Table</a>&lt;<b>address</b>, <a href="reward_vault.md#0xcafebabe_reward_vault_Vault">reward_vault::Vault</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_reward_vault_Debt"></a>

## Struct `Debt`



<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Debt">Debt</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>recv: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_reward_vault_RewardTransmitter"></a>

## Resource `RewardTransmitter`

Stores transmission settings in a resource account, which will also hold the reward coins.


<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>available: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>reward_rate: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>num_receivers: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>debt_queue: <a href="_Queue">queue::Queue</a>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Debt">reward_vault::Debt</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>sign_capability: <a href="_SignerCapability">account::SignerCapability</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_reward_vault_RewardVault"></a>

## Resource `RewardVault`

Single transmitter, multiple receivers.


<pre><code><b>struct</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>tx: <b>address</b></code>
</dt>
<dd>
 Vault transmitter handle.
</dd>
<dt>
<code>rxs: <a href="">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>
 Vault receiver handles.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xcafebabe_reward_vault_ERESOURCE_DNE"></a>

Resource does not exist.


<pre><code><b>const</b> <a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>: u64 = 1;
</code></pre>



<a name="0xcafebabe_reward_vault_EINSUFFICIENT_REWARDS"></a>

Insufficient rewards in vault.


<pre><code><b>const</b> <a href="reward_vault.md#0xcafebabe_reward_vault_EINSUFFICIENT_REWARDS">EINSUFFICIENT_REWARDS</a>: u64 = 2;
</code></pre>



<a name="0xcafebabe_reward_vault_ERESOURCE_ALREADY_EXISTS"></a>

Resource already exists.


<pre><code><b>const</b> <a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>: u64 = 0;
</code></pre>



<a name="0xcafebabe_reward_vault_MODIFIER_MUL"></a>

Modifier kind variants.


<pre><code><b>const</b> <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_MUL">MODIFIER_MUL</a>: u8 = 1;
</code></pre>



<a name="0xcafebabe_reward_vault_MODIFIER_SUM"></a>

Modifier kind variants.


<pre><code><b>const</b> <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_SUM">MODIFIER_SUM</a>: u8 = 0;
</code></pre>



<a name="0xcafebabe_reward_vault_publish_reward_vault"></a>

## Function `publish_reward_vault`

Move a new RewardVault to account and create a transmitter
resource for it.


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_publish_reward_vault">publish_reward_vault</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, reward_rate: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_publish_reward_vault">publish_reward_vault</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    reward_rate: u64
) {
    <b>let</b> (resource, sign_capability) =
        <a href="_create_resource_account">account::create_resource_account</a>(<a href="">account</a>, b"transmitter");
    <b>let</b> resource_addr = <a href="_address_of">signer::address_of</a>(&resource);

    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(<a href="_address_of">signer::address_of</a>(<a href="">account</a>)),
        <a href="_already_exists">error::already_exists</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>)
    );
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(resource_addr),
        <a href="_already_exists">error::already_exists</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>)
    );

    <a href="_register">coin::register</a>&lt;CoinType&gt;(&resource);

    <b>move_to</b>(&resource, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt; {
        available: 0,
        num_receivers: 0,
        reward_rate,
        debt_queue: <a href="_new">queue::new</a>(),
        sign_capability,
    });

    <b>move_to</b>(<a href="">account</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt; {
        tx: resource_addr,
        rxs: <a href="_empty">vector::empty</a>()
    });
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_fund_vault"></a>

## Function `fund_vault`

Transfer coins to reward transmitter.
Must be done by the creator.


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_fund_vault">fund_vault</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_fund_vault">fund_vault</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    amount: u64
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <a href="reward_vault.md#0xcafebabe_reward_vault_assert_reward_vault_exists">assert_reward_vault_exists</a>&lt;CoinType&gt;(addr);

    <b>let</b> tx_addr = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(addr).tx;
    <a href="_transfer">coin::transfer</a>&lt;CoinType&gt;(<a href="">account</a>, tx_addr, amount);

    <b>let</b> tx = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(tx_addr);
    tx.available = tx.available + amount;

    <b>let</b> tx_signature = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(&tx.sign_capability);

    <b>if</b> (!<a href="_is_empty">queue::is_empty</a>(&tx.debt_queue)) {
        // Pay accrued debts.
        <a href="reward_vault.md#0xcafebabe_reward_vault_pay_debts">pay_debts</a>&lt;CoinType&gt;(&tx_signature);
    }
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_pay_debts"></a>

## Function `pay_debts`



<pre><code><b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_pay_debts">pay_debts</a>&lt;CoinType&gt;(tx: &<a href="">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_pay_debts">pay_debts</a>&lt;CoinType&gt;(tx: &<a href="">signer</a>) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(tx);
    <b>let</b> transmitter = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(addr);
    <b>let</b> debt_queue = &<b>mut</b> transmitter.debt_queue;

    <b>let</b> first = <a href="_pop_front">queue::pop_front</a>(debt_queue);
    <b>while</b> (<a href="_is_some">option::is_some</a>(&first)) {
        <b>let</b> debt = <a href="_extract">option::extract</a>(&<b>mut</b> first);
        <b>let</b> available = transmitter.available;

        <b>if</b> (debt.amount &lt;= available) {
            <a href="_transfer">coin::transfer</a>&lt;CoinType&gt;(tx, debt.recv, debt.amount);
            transmitter.available = transmitter.available - debt.amount;
        } <b>else</b> {
            <b>let</b> amount = debt.amount - available;
            <a href="_transfer">coin::transfer</a>&lt;CoinType&gt;(tx, debt.recv, amount);
            debt.amount = debt.amount - amount;
            <a href="_push_back">queue::push_back</a>(debt_queue, debt);
            transmitter.available = 0;
            <b>break</b>
        };

        first = <a href="_pop_front">queue::pop_front</a>(debt_queue);
    };
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_withdraw_funds"></a>

## Function `withdraw_funds`

Withdraw funds from reward transmitter.
Must be done by the creator.


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_withdraw_funds">withdraw_funds</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_withdraw_funds">withdraw_funds</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    amount: u64
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <a href="reward_vault.md#0xcafebabe_reward_vault_assert_reward_vault_exists">assert_reward_vault_exists</a>&lt;CoinType&gt;(addr);

    <b>let</b> tx_addr = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(addr).tx;
    <b>let</b> tx = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(tx_addr);
    <b>assert</b>!(tx.available &gt;= amount, <a href="_invalid_argument">error::invalid_argument</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_EINSUFFICIENT_REWARDS">EINSUFFICIENT_REWARDS</a>));

    tx.available = tx.available - amount;
    <b>let</b> tx_signature = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(
        &tx.sign_capability
    );
    <a href="_transfer">coin::transfer</a>&lt;CoinType&gt;(&tx_signature, addr, amount);
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_subscribe"></a>

## Function `subscribe`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_subscribe">subscribe</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, vault: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_subscribe">subscribe</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    vault: <b>address</b>
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <a href="reward_vault.md#0xcafebabe_reward_vault_internal_subscribe">internal_subscribe</a>&lt;CoinType&gt;(<a href="">account</a>, vault, <a href="_none">option::none</a>());
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_subscribe_with_modifier"></a>

## Function `subscribe_with_modifier`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_subscribe_with_modifier">subscribe_with_modifier</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, vault: <b>address</b>, modifier: <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_subscribe_with_modifier">subscribe_with_modifier</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    vault: <b>address</b>,
    modifier: <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a>
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <a href="reward_vault.md#0xcafebabe_reward_vault_internal_subscribe">internal_subscribe</a>&lt;CoinType&gt;(<a href="">account</a>, vault, <a href="_some">option::some</a>(modifier));
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_internal_subscribe"></a>

## Function `internal_subscribe`



<pre><code><b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_internal_subscribe">internal_subscribe</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, vault: <b>address</b>, modifier: <a href="_Option">option::Option</a>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_internal_subscribe">internal_subscribe</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    vault: <b>address</b>,
    modifier: Option&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a>&gt;
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>let</b>  <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a> { tx, rxs } =
        <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault);
    <b>let</b> tx = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(*tx);

    <a href="_push_back">vector::push_back</a>(rxs, addr);
    tx.num_receivers = tx.num_receivers + 1;

    <b>if</b> (!<a href="_is_account_registered">coin::is_account_registered</a>&lt;CoinType&gt;(addr)) {
        <a href="_register">coin::register</a>&lt;CoinType&gt;(<a href="">account</a>);
    };

    <b>let</b> now_ts = <a href="_now_seconds">timestamp::now_seconds</a>();

    <b>if</b> (!<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(addr)) {
        <b>let</b> vaults = <a href="_new">table::new</a>();
        <a href="_add">table::add</a>(&<b>mut</b> vaults, vault, <a href="reward_vault.md#0xcafebabe_reward_vault_Vault">Vault</a> {
            start_ts: now_ts,
            accrued_rewards: 0,
            last_update_ts: now_ts,
            modifier,
        });
        <b>move_to</b>(<a href="">account</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt; { vaults });
    } <b>else</b> {
        <b>let</b> recv = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(addr);
        <b>assert</b>!(
            !<a href="_contains">table::contains</a>(&recv.vaults, vault),
            <a href="_already_exists">error::already_exists</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>)
        );
        <a href="_add">table::add</a>(&<b>mut</b> recv.vaults, vault, <a href="reward_vault.md#0xcafebabe_reward_vault_Vault">Vault</a> {
            start_ts: now_ts,
            accrued_rewards: 0,
            last_update_ts: now_ts,
            modifier,
        });
    };

}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_unsubscribe"></a>

## Function `unsubscribe`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_unsubscribe">unsubscribe</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, vault: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_unsubscribe">unsubscribe</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    vault: <b>address</b>
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    // claim accrued rewards.
    <a href="reward_vault.md#0xcafebabe_reward_vault_claim">claim</a>&lt;CoinType&gt;(<a href="">account</a>, vault);

    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a> { tx, rxs } =
        <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault);
    <b>let</b> tx = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(*tx);

    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>let</b> (exist, i) = <a href="_index_of">vector::index_of</a>(rxs, &addr);
    <b>assert</b>!(exist, <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <a href="_remove">vector::remove</a>(rxs, i);
    tx.num_receivers = tx.num_receivers - 1;

    <b>let</b> recv = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(addr);
    <a href="_remove">table::remove</a>(&<b>mut</b> recv.vaults, vault);
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_claim"></a>

## Function `claim`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_claim">claim</a>&lt;CoinType&gt;(<a href="">account</a>: &<a href="">signer</a>, vault: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_claim">claim</a>&lt;CoinType&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    vault: <b>address</b>
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);

    <b>assert</b>!(
        <b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(addr),
        <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>)
    );

    <b>assert</b>!(<a href="reward_vault.md#0xcafebabe_reward_vault_is_subscribed">is_subscribed</a>&lt;CoinType&gt;(addr, vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <a href="reward_vault.md#0xcafebabe_reward_vault_update_accrued_rewards">update_accrued_rewards</a>&lt;CoinType&gt;(addr, vault, <a href="_now_seconds">timestamp::now_seconds</a>());

    <b>let</b> recv = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(addr);
    <b>let</b> vault_ref = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> recv.vaults, vault);
    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault">reward_vault</a> = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault);
    <b>let</b> tx = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(<a href="reward_vault.md#0xcafebabe_reward_vault">reward_vault</a>.tx);
    <b>let</b> reward = vault_ref.accrued_rewards;

    <b>let</b> tx_sig =
        <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(&tx.sign_capability);

    <b>assert</b>!(
        <a href="_is_account_registered">coin::is_account_registered</a>&lt;CoinType&gt;(<a href="_address_of">signer::address_of</a>(&tx_sig)),
        <a href="_invalid_state">error::invalid_state</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_EINSUFFICIENT_REWARDS">EINSUFFICIENT_REWARDS</a>)
    );

    // Add user <b>to</b> debt <a href="">queue</a> <b>if</b> there is not enough reward available
    <b>if</b> (reward &gt; tx.available) {
        <b>let</b> debt_amount = reward - tx.available;
        <a href="_push_back">queue::push_back</a>(&<b>mut</b> tx.debt_queue, <a href="reward_vault.md#0xcafebabe_reward_vault_Debt">Debt</a> { recv: addr, amount: debt_amount });
        reward = tx.available;
   };

    <b>if</b> (reward &gt; 0) {
        <a href="_transfer">coin::transfer</a>&lt;CoinType&gt;(&tx_sig, addr, reward);
    };

    tx.available = tx.available - reward;
    vault_ref.accrued_rewards = 0;
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_update_accrued_rewards"></a>

## Function `update_accrued_rewards`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_update_accrued_rewards">update_accrued_rewards</a>&lt;CoinType&gt;(recv_addr: <b>address</b>, vault: <b>address</b>, now: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_update_accrued_rewards">update_accrued_rewards</a>&lt;CoinType&gt;(
    recv_addr: <b>address</b>,
    vault: <b>address</b>,
    now: u64
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> recv = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(recv_addr);
    <a href="reward_vault.md#0xcafebabe_reward_vault_assert_reward_vault_exists">assert_reward_vault_exists</a>&lt;CoinType&gt;(vault);

    <b>let</b> transmitter_addr = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault).tx;
    <b>let</b> transmitter = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a>&lt;CoinType&gt;&gt;(transmitter_addr);

    <b>let</b> vault = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> recv.vaults, vault);

    <b>let</b> elapsed = now - vault.last_update_ts;
    <b>let</b> reward_rate = <b>if</b> (<a href="_is_some">option::is_some</a>(&vault.modifier)) {
        <b>let</b> modifier = <a href="_borrow">option::borrow</a>(&vault.modifier);
        <b>if</b> (modifier.kind == <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_SUM">MODIFIER_SUM</a>) {
            transmitter.reward_rate + modifier.value
        } <b>else</b> {
            transmitter.reward_rate * modifier.value
        }
    } <b>else</b> {
        transmitter.reward_rate
    };
    vault.accrued_rewards = vault.accrued_rewards + reward_rate * elapsed;
    vault.last_update_ts = now;
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_increase_modifier_value"></a>

## Function `increase_modifier_value`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_increase_modifier_value">increase_modifier_value</a>&lt;CoinType&gt;(vault: &<a href="">signer</a>, <a href="">account</a>: <b>address</b>, lhs: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_increase_modifier_value">increase_modifier_value</a>&lt;CoinType&gt;(
    vault: &<a href="">signer</a>,
    <a href="">account</a>: <b>address</b>,
    lhs: u64
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> vault_addr = <a href="_address_of">signer::address_of</a>(vault);
    <b>let</b> recv = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>);
    <b>assert</b>!(<a href="_contains">table::contains</a>(&recv.vaults, vault_addr), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <b>let</b> vault_ref = <a href="_borrow">table::borrow</a>(&recv.vaults, vault_addr);
    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind, value } = <a href="_borrow_with_default">option::borrow_with_default</a>(&vault_ref.modifier, &<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { value: 1, kind: <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_MUL">MODIFIER_MUL</a> });
    <a href="reward_vault.md#0xcafebabe_reward_vault_update_modifier">update_modifier</a>&lt;CoinType&gt;(vault, <a href="">account</a>, <a href="_some">option::some</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind: *kind, value: *value + lhs } ));
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_decrease_modifier_value"></a>

## Function `decrease_modifier_value`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_decrease_modifier_value">decrease_modifier_value</a>&lt;CoinType&gt;(vault: &<a href="">signer</a>, <a href="">account</a>: <b>address</b>, lhs: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_decrease_modifier_value">decrease_modifier_value</a>&lt;CoinType&gt;(
    vault: &<a href="">signer</a>,
    <a href="">account</a>: <b>address</b>,
    lhs: u64
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> vault_addr = <a href="_address_of">signer::address_of</a>(vault);
    <b>let</b> recv = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>);
    <b>assert</b>!(<a href="_contains">table::contains</a>(&recv.vaults, vault_addr), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <b>let</b> vault_ref = <a href="_borrow">table::borrow</a>(&recv.vaults, vault_addr);
    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind, value } = <a href="_borrow_with_default">option::borrow_with_default</a>(&vault_ref.modifier, &<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { value: 1, kind: <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_MUL">MODIFIER_MUL</a> });
    <a href="reward_vault.md#0xcafebabe_reward_vault_update_modifier">update_modifier</a>&lt;CoinType&gt;(vault, <a href="">account</a>, <a href="_some">option::some</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind: *kind, value: *value - lhs } ));
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_update_modifier"></a>

## Function `update_modifier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_update_modifier">update_modifier</a>&lt;CoinType&gt;(vault: &<a href="">signer</a>, <a href="">account</a>: <b>address</b>, modifier: <a href="_Option">option::Option</a>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_update_modifier">update_modifier</a>&lt;CoinType&gt;(
    vault: &<a href="">signer</a>,
    <a href="">account</a>: <b>address</b>,
    modifier: Option&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a>&gt;
) <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>let</b> vault_addr = <a href="_address_of">signer::address_of</a>(vault);

    <a href="reward_vault.md#0xcafebabe_reward_vault_update_accrued_rewards">update_accrued_rewards</a>&lt;CoinType&gt;(<a href="">account</a>, vault_addr, <a href="_now_seconds">timestamp::now_seconds</a>());

    <b>let</b> receiver = <b>borrow_global_mut</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>);
    <b>assert</b>!(
        <a href="_contains">table::contains</a>(&receiver.vaults, vault_addr),
        <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>)
    );
    <b>let</b> vault_ref = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> receiver.vaults, vault_addr);
    vault_ref.modifier = modifier;
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_create_sum_modifier"></a>

## Function `create_sum_modifier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_create_sum_modifier">create_sum_modifier</a>(value: u64): <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_create_sum_modifier">create_sum_modifier</a>(value: u64): <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> {
    <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind: <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_SUM">MODIFIER_SUM</a>, value }
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_create_mul_modifier"></a>

## Function `create_mul_modifier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_create_mul_modifier">create_mul_modifier</a>(value: u64): <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">reward_vault::Modifier</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_create_mul_modifier">create_mul_modifier</a>(value: u64): <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> {
    <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind: <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_MUL">MODIFIER_MUL</a>, value }
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_get_modifier"></a>

## Function `get_modifier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_get_modifier">get_modifier</a>&lt;CoinType&gt;(<a href="">account</a>: <b>address</b>, vault: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_get_modifier">get_modifier</a>&lt;CoinType&gt;(
    <a href="">account</a>: <b>address</b>,
    vault: <b>address</b>
): u64 <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <b>let</b> recv = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>);
    <b>assert</b>!(<a href="_contains">table::contains</a>(&recv.vaults, vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <b>let</b> vault = <a href="_borrow">table::borrow</a>(&recv.vaults, vault);
    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { kind: _, value } = <a href="_borrow_with_default">option::borrow_with_default</a>(
        &vault.modifier,
        &<a href="reward_vault.md#0xcafebabe_reward_vault_Modifier">Modifier</a> { value: 0, kind: <a href="reward_vault.md#0xcafebabe_reward_vault_MODIFIER_MUL">MODIFIER_MUL</a> }
    );
    *value
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_get_accrued_rewards"></a>

## Function `get_accrued_rewards`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_get_accrued_rewards">get_accrued_rewards</a>&lt;CoinType&gt;(<a href="">account</a>: <b>address</b>, vault: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_get_accrued_rewards">get_accrued_rewards</a>&lt;CoinType&gt;(
    <a href="">account</a>: <b>address</b>,
    vault: <b>address</b>
): u64 <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>, <a href="reward_vault.md#0xcafebabe_reward_vault_RewardTransmitter">RewardTransmitter</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<a href="reward_vault.md#0xcafebabe_reward_vault_is_subscribed">is_subscribed</a>&lt;CoinType&gt;(<a href="">account</a>, vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <a href="reward_vault.md#0xcafebabe_reward_vault_update_accrued_rewards">update_accrued_rewards</a>&lt;CoinType&gt;(<a href="">account</a>, vault, <a href="_now_seconds">timestamp::now_seconds</a>());

    <b>let</b> recv = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardReceiver">RewardReceiver</a>&lt;CoinType&gt;&gt;(<a href="">account</a>);
    <b>assert</b>!(<a href="_contains">table::contains</a>(&recv.vaults, vault), <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>));

    <b>let</b> vault = <a href="_borrow">table::borrow</a>(&recv.vaults, vault);
    vault.accrued_rewards
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_is_subscribed"></a>

## Function `is_subscribed`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_is_subscribed">is_subscribed</a>&lt;CoinType&gt;(<a href="">account</a>: <b>address</b>, vault: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_is_subscribed">is_subscribed</a>&lt;CoinType&gt;(
    <a href="">account</a>: <b>address</b>,
    vault: <b>address</b>
): bool <b>acquires</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a> {
    <b>if</b> (!<b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault)) {
        <b>return</b> <b>false</b>
    };
    <b>let</b> <a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a> { rxs, tx: _ } = <b>borrow_global</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(vault);
    <a href="_contains">vector::contains</a>(rxs, &<a href="">account</a>)
}
</code></pre>



</details>

<a name="0xcafebabe_reward_vault_assert_reward_vault_exists"></a>

## Function `assert_reward_vault_exists`



<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_assert_reward_vault_exists">assert_reward_vault_exists</a>&lt;CoinType&gt;(addr: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="reward_vault.md#0xcafebabe_reward_vault_assert_reward_vault_exists">assert_reward_vault_exists</a>&lt;CoinType&gt;(addr: <b>address</b>) {
    <b>assert</b>!(
        <b>exists</b>&lt;<a href="reward_vault.md#0xcafebabe_reward_vault_RewardVault">RewardVault</a>&lt;CoinType&gt;&gt;(addr),
        <a href="_not_found">error::not_found</a>(<a href="reward_vault.md#0xcafebabe_reward_vault_ERESOURCE_DNE">ERESOURCE_DNE</a>)
    );
}
</code></pre>



</details>
