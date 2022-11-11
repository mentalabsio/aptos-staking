
<a name="0xcafebabe_farm"></a>

# Module `0xcafebabe::farm`



-  [Resource `Farm`](#0xcafebabe_farm_Farm)
-  [Resource `Farmer`](#0xcafebabe_farm_Farmer)
-  [Constants](#@Constants_0)
-  [Function `publish_farm`](#0xcafebabe_farm_publish_farm)
-  [Function `fund_reward`](#0xcafebabe_farm_fund_reward)
-  [Function `withdraw_reward`](#0xcafebabe_farm_withdraw_reward)
-  [Function `add_to_whitelist`](#0xcafebabe_farm_add_to_whitelist)
-  [Function `register_farmer`](#0xcafebabe_farm_register_farmer)
-  [Function `stake`](#0xcafebabe_farm_stake)
-  [Function `unstake`](#0xcafebabe_farm_unstake)
-  [Function `claim_rewards`](#0xcafebabe_farm_claim_rewards)
-  [Function `find_farm_address`](#0xcafebabe_farm_find_farm_address)
-  [Function `get_accrued_rewards`](#0xcafebabe_farm_get_accrued_rewards)
-  [Function `get_staked`](#0xcafebabe_farm_get_staked)
-  [Function `is_registered`](#0xcafebabe_farm_is_registered)
-  [Function `is_whitelisted`](#0xcafebabe_farm_is_whitelisted)
-  [Function `get_farmers`](#0xcafebabe_farm_get_farmers)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::error</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::table</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0x3::token</a>;
<b>use</b> <a href="bank.md#0xcafebabe_bank">0xcafebabe::bank</a>;
<b>use</b> <a href="reward_vault.md#0xcafebabe_reward_vault">0xcafebabe::reward_vault</a>;
</code></pre>



<a name="0xcafebabe_farm_Farm"></a>

## Resource `Farm`

Farm resource, stored in a resource account.
Generic over R, which is the reward coin type.


<pre><code><b>struct</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>whitelisted_collections: <a href="_Table">table::Table</a>&lt;<a href="_String">string::String</a>, u64&gt;</code>
</dt>
<dd>
 Whitelist of collections that can be staked in the farm (keys),
 and the reward rate for each collection (values).
</dd>
<dt>
<code>farmer_handles: <a href="">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>
 Farmers' addresses.
</dd>
<dt>
<code>sign_cap: <a href="_SignerCapability">account::SignerCapability</a></code>
</dt>
<dd>
 Signature capability.
</dd>
</dl>


</details>

<a name="0xcafebabe_farm_Farmer"></a>

## Resource `Farmer`

Farmer resource, stored in the user account.
For now, only stores a table containing the farms and the staked tokens' TokenIds,
but can be extended to store other information.


<pre><code><b>struct</b> <a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>staked: <a href="_Table">table::Table</a>&lt;<b>address</b>, <a href="">vector</a>&lt;<a href="_TokenId">token::TokenId</a>&gt;&gt;</code>
</dt>
<dd>
 The same farmer can be registered in many farms.
 This field is used to keep track of the farms the farmer is registered in (table keys),
 and the token ids the farmer has staked in each farm.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xcafebabe_farm_EALREADY_REGISTERED"></a>

User is already registered in a farm.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_EALREADY_REGISTERED">EALREADY_REGISTERED</a>: u64 = 7;
</code></pre>



<a name="0xcafebabe_farm_ERESOURCE_DNE"></a>

Resource does not exist.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>: u64 = 1;
</code></pre>



<a name="0xcafebabe_farm_ERESOURCE_ALREADY_EXISTS"></a>

Resource already exists.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>: u64 = 0;
</code></pre>



<a name="0xcafebabe_farm_EALREADY_STAKED"></a>

NFT is already staked


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_EALREADY_STAKED">EALREADY_STAKED</a>: u64 = 4;
</code></pre>



<a name="0xcafebabe_farm_ECOLLECTION_ALREADY_WHITELISTED"></a>

Collection is already whitelisted.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ECOLLECTION_ALREADY_WHITELISTED">ECOLLECTION_ALREADY_WHITELISTED</a>: u64 = 3;
</code></pre>



<a name="0xcafebabe_farm_ECOLLECTION_NOT_WHITELISTED"></a>

Collection is not whitelisted.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ECOLLECTION_NOT_WHITELISTED">ECOLLECTION_NOT_WHITELISTED</a>: u64 = 2;
</code></pre>



<a name="0xcafebabe_farm_ENOT_REGISTERED"></a>

User is not registered in a farm.


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ENOT_REGISTERED">ENOT_REGISTERED</a>: u64 = 6;
</code></pre>



<a name="0xcafebabe_farm_ENOT_STAKED"></a>

NFT is not staked


<pre><code><b>const</b> <a href="farm.md#0xcafebabe_farm_ENOT_STAKED">ENOT_STAKED</a>: u64 = 5;
</code></pre>



<a name="0xcafebabe_farm_publish_farm"></a>

## Function `publish_farm`

Publishes a new farm under a new resource account.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_publish_farm">publish_farm</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_publish_farm">publish_farm</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>) {
    <b>let</b> (<a href="farm.md#0xcafebabe_farm">farm</a>, sign_cap) = <a href="_create_resource_account">account::create_resource_account</a>(<a href="">account</a>, b"<a href="farm.md#0xcafebabe_farm">farm</a>");
    <a href="_register">coin::register</a>&lt;R&gt;(&<a href="farm.md#0xcafebabe_farm">farm</a>);
    <a href="reward_vault.md#0xcafebabe_reward_vault_publish_reward_vault">reward_vault::publish_reward_vault</a>&lt;R&gt;(&<a href="farm.md#0xcafebabe_farm">farm</a>, 0);

    <b>let</b> farm_addr = <a href="_address_of">signer::address_of</a>(&<a href="farm.md#0xcafebabe_farm">farm</a>);
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(farm_addr),
        <a href="_already_exists">error::already_exists</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_ALREADY_EXISTS">ERESOURCE_ALREADY_EXISTS</a>)
    );

    <b>move_to</b>(&<a href="farm.md#0xcafebabe_farm">farm</a>, <a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt; {
        sign_cap,
        farmer_handles: <a href="_empty">vector::empty</a>(),
        whitelisted_collections: <a href="_new">table::new</a>(),
    });
}
</code></pre>



</details>

<a name="0xcafebabe_farm_fund_reward"></a>

## Function `fund_reward`

Add funds to the farm's reward vault.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_fund_reward">fund_reward</a>&lt;R&gt;(creator: &<a href="">signer</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_fund_reward">fund_reward</a>&lt;R&gt;(creator: &<a href="">signer</a>, amount: u64) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>let</b> farm_addr = <a href="farm.md#0xcafebabe_farm_find_farm_address">find_farm_address</a>(&<a href="_address_of">signer::address_of</a>(creator));
    <a href="_transfer">coin::transfer</a>&lt;R&gt;(creator, farm_addr, amount);

    <b>let</b> <a href="farm.md#0xcafebabe_farm">farm</a> = <b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(farm_addr);
    <b>let</b> farm_signer = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(&<a href="farm.md#0xcafebabe_farm">farm</a>.sign_cap);
    <a href="reward_vault.md#0xcafebabe_reward_vault_fund_vault">reward_vault::fund_vault</a>&lt;R&gt;(&farm_signer, amount);
}
</code></pre>



</details>

<a name="0xcafebabe_farm_withdraw_reward"></a>

## Function `withdraw_reward`

Withdraw funds from the farm's reward vault.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_withdraw_reward">withdraw_reward</a>&lt;R&gt;(creator: &<a href="">signer</a>, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_withdraw_reward">withdraw_reward</a>&lt;R&gt;(creator: &<a href="">signer</a>, amount: u64) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>let</b> farm_addr = <a href="farm.md#0xcafebabe_farm_find_farm_address">find_farm_address</a>(&<a href="_address_of">signer::address_of</a>(creator));
    <b>let</b> <a href="farm.md#0xcafebabe_farm">farm</a> = <b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(farm_addr);
    <b>let</b> farm_signer = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(&<a href="farm.md#0xcafebabe_farm">farm</a>.sign_cap);
    <a href="reward_vault.md#0xcafebabe_reward_vault_withdraw_funds">reward_vault::withdraw_funds</a>&lt;R&gt;(&farm_signer, amount);
    <a href="_transfer">coin::transfer</a>&lt;R&gt;(&farm_signer, <a href="_address_of">signer::address_of</a>(creator), amount);
}
</code></pre>



</details>

<a name="0xcafebabe_farm_add_to_whitelist"></a>

## Function `add_to_whitelist`

Whitelist a collection for staking.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_add_to_whitelist">add_to_whitelist</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, collection_name: <a href="_String">string::String</a>, collection_reward_rate: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_add_to_whitelist">add_to_whitelist</a>&lt;R&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    collection_name: String,
    collection_reward_rate: u64,
) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>let</b> farm_addr = <a href="farm.md#0xcafebabe_farm_find_farm_address">find_farm_address</a>(&<a href="_address_of">signer::address_of</a>(<a href="">account</a>));
    <b>assert</b>!(
        <b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(farm_addr),
        <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>)
    );

    <b>let</b> <a href="farm.md#0xcafebabe_farm">farm</a> = <b>borrow_global_mut</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(farm_addr);

    <b>assert</b>!(
        !<a href="_contains">table::contains</a>(&<a href="farm.md#0xcafebabe_farm">farm</a>.whitelisted_collections, collection_name),
        <a href="_already_exists">error::already_exists</a>(<a href="farm.md#0xcafebabe_farm_ECOLLECTION_ALREADY_WHITELISTED">ECOLLECTION_ALREADY_WHITELISTED</a>)
    );

    <a href="_add">table::add</a>(
        &<b>mut</b> <a href="farm.md#0xcafebabe_farm">farm</a>.whitelisted_collections,
        collection_name,
        collection_reward_rate
    );
}
</code></pre>



</details>

<a name="0xcafebabe_farm_register_farmer"></a>

## Function `register_farmer`

Register a farmer in a farm.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_register_farmer">register_farmer</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_register_farmer">register_farmer</a>&lt;R&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>
) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>assert</b>!(
        <b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>),
        <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>)
    );

    <b>let</b> farmer_addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);

    <b>assert</b>!(
        !<a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(&farmer_addr, <a href="farm.md#0xcafebabe_farm">farm</a>),
        <a href="_already_exists">error::already_exists</a>(<a href="farm.md#0xcafebabe_farm_EALREADY_REGISTERED">EALREADY_REGISTERED</a>)
    );

    // Allocate farmer resource <b>if</b> it does not exist.
    <b>if</b> (!<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(farmer_addr)) {
        <b>let</b> staked = <a href="_new">table::new</a>();
        <a href="_add">table::add</a>(&<b>mut</b> staked, <a href="farm.md#0xcafebabe_farm">farm</a>, <a href="_empty">vector::empty</a>());
        <b>move_to</b>(<a href="">account</a>, <a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a> { staked, });
    };

    // Publish a <a href="bank.md#0xcafebabe_bank">bank</a> for the farmer.
    <b>if</b> (!<a href="bank.md#0xcafebabe_bank_bank_exists">bank::bank_exists</a>(&farmer_addr)) {
        <a href="bank.md#0xcafebabe_bank_publish_bank">bank::publish_bank</a>(<a href="">account</a>);
    };

    // Register farmer in <a href="farm.md#0xcafebabe_farm">farm</a>.
    <b>let</b> <a href="farm.md#0xcafebabe_farm">farm</a> = <b>borrow_global_mut</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>);
    <a href="_push_back">vector::push_back</a>(&<b>mut</b> <a href="farm.md#0xcafebabe_farm">farm</a>.farmer_handles, farmer_addr);
}
</code></pre>



</details>

<a name="0xcafebabe_farm_stake"></a>

## Function `stake`

Stake an NFT in a farm.


<pre><code><b>public</b> <b>fun</b> <a href="">stake</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="">stake</a>&lt;R&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>,
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>
) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a>, <a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a> {
    <b>let</b> (_, collection, _, _) = <a href="_get_token_id_fields">token::get_token_id_fields</a>(&token_id);
    <b>assert</b>!(<a href="farm.md#0xcafebabe_farm_is_whitelisted">is_whitelisted</a>&lt;R&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>, collection), 1);

    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>if</b> (!<a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(&addr, <a href="farm.md#0xcafebabe_farm">farm</a>)) {
        <a href="farm.md#0xcafebabe_farm_register_farmer">register_farmer</a>&lt;R&gt;(<a href="">account</a>, <a href="farm.md#0xcafebabe_farm">farm</a>);
    };

    <b>let</b> farmer = <b>borrow_global_mut</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(addr);
    <b>let</b> staked = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> farmer.staked, <a href="farm.md#0xcafebabe_farm">farm</a>);
    <b>assert</b>!(
        !<a href="_contains">vector::contains</a>(staked, &token_id),
        <a href="_invalid_state">error::invalid_state</a>(<a href="farm.md#0xcafebabe_farm_EALREADY_STAKED">EALREADY_STAKED</a>)
    );
    <a href="_push_back">vector::push_back</a>(staked, token_id);

    // Lock the <a href="">token</a> in a <a href="bank.md#0xcafebabe_bank">bank</a>
    <a href="bank.md#0xcafebabe_bank_deposit">bank::deposit</a>(<a href="">account</a>, token_id, 1);

    <b>let</b> collection_modifier = <a href="_borrow">table::borrow</a>(
        &<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).whitelisted_collections,
        collection
    );

    <b>if</b> (!<a href="reward_vault.md#0xcafebabe_reward_vault_is_subscribed">reward_vault::is_subscribed</a>&lt;R&gt;(addr, <a href="farm.md#0xcafebabe_farm">farm</a>)) {
        <b>let</b> modifier = <a href="reward_vault.md#0xcafebabe_reward_vault_create_sum_modifier">reward_vault::create_sum_modifier</a>(
            *collection_modifier
        );
        <a href="reward_vault.md#0xcafebabe_reward_vault_subscribe_with_modifier">reward_vault::subscribe_with_modifier</a>&lt;R&gt;(
            <a href="">account</a>,
            <a href="farm.md#0xcafebabe_farm">farm</a>,
            modifier
        );
    } <b>else</b> {
        <b>let</b> identity = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(
            &<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).sign_cap
        );
        <a href="reward_vault.md#0xcafebabe_reward_vault_increase_modifier_value">reward_vault::increase_modifier_value</a>&lt;R&gt;(
            &identity,
            <a href="_address_of">signer::address_of</a>(<a href="">account</a>),
            *collection_modifier
        );
    };
}
</code></pre>



</details>

<a name="0xcafebabe_farm_unstake"></a>

## Function `unstake`

Unstake an NFT from a farm.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_unstake">unstake</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, token_id: <a href="_TokenId">token::TokenId</a>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_unstake">unstake</a>&lt;R&gt;(
    <a href="">account</a>: &<a href="">signer</a>,
    token_id: <a href="_TokenId">token::TokenId</a>,
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>
) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a>, <a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a> {
    <b>let</b> addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>assert</b>!(<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(addr), <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>), <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(&addr, <a href="farm.md#0xcafebabe_farm">farm</a>), <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ENOT_REGISTERED">ENOT_REGISTERED</a>));

    <b>let</b> farmer = <b>borrow_global_mut</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(addr);
    <b>let</b> staked = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> farmer.staked, <a href="farm.md#0xcafebabe_farm">farm</a>);

    <b>let</b> (exist, index) = <a href="_index_of">vector::index_of</a>(staked, &token_id);
    <b>assert</b>!(exist, <a href="_invalid_state">error::invalid_state</a>(<a href="farm.md#0xcafebabe_farm_ENOT_STAKED">ENOT_STAKED</a>));
    <a href="_remove">vector::remove</a>(staked, index);

    // Unlock the <a href="">token</a> from the <a href="bank.md#0xcafebabe_bank">bank</a>
    <a href="bank.md#0xcafebabe_bank_withdraw">bank::withdraw</a>(<a href="">account</a>, token_id);

    <a href="farm.md#0xcafebabe_farm_claim_rewards">claim_rewards</a>&lt;R&gt;(<a href="">account</a>, <a href="farm.md#0xcafebabe_farm">farm</a>);

    // Unsubscribe from reward vault.
    <b>if</b> (<a href="_is_empty">vector::is_empty</a>(staked)) {
        <a href="reward_vault.md#0xcafebabe_reward_vault_unsubscribe">reward_vault::unsubscribe</a>&lt;R&gt;(<a href="">account</a>, <a href="farm.md#0xcafebabe_farm">farm</a>);
    } <b>else</b> {
        <b>let</b> (_, collection, _, _) = <a href="_get_token_id_fields">token::get_token_id_fields</a>(&token_id);
        <b>let</b> collection_modifier = <a href="_borrow">table::borrow</a>(
            &<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).whitelisted_collections,
            collection
        );
        <b>let</b> identity = <a href="_create_signer_with_capability">account::create_signer_with_capability</a>(
            &<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).sign_cap
        );
        <a href="reward_vault.md#0xcafebabe_reward_vault_decrease_modifier_value">reward_vault::decrease_modifier_value</a>&lt;R&gt;(&identity, addr, *collection_modifier);
    };
}
</code></pre>



</details>

<a name="0xcafebabe_farm_claim_rewards"></a>

## Function `claim_rewards`

Claim rewards from a farm.


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_claim_rewards">claim_rewards</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="farm.md#0xcafebabe_farm_claim_rewards">claim_rewards</a>&lt;R&gt;(<a href="">account</a>: &<a href="">signer</a>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>) <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>let</b> user_addr = <a href="_address_of">signer::address_of</a>(<a href="">account</a>);
    <b>assert</b>!(<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(user_addr), <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>assert</b>!(<a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(&user_addr, <a href="farm.md#0xcafebabe_farm">farm</a>), <a href="_invalid_state">error::invalid_state</a>(<a href="farm.md#0xcafebabe_farm_ENOT_REGISTERED">ENOT_REGISTERED</a>));
    <a href="reward_vault.md#0xcafebabe_reward_vault_claim">reward_vault::claim</a>&lt;R&gt;(<a href="">account</a>, <a href="farm.md#0xcafebabe_farm">farm</a>);
}
</code></pre>



</details>

<a name="0xcafebabe_farm_find_farm_address"></a>

## Function `find_farm_address`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_find_farm_address">find_farm_address</a>(creator: &<b>address</b>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_find_farm_address">find_farm_address</a>(creator: &<b>address</b>): <b>address</b> {
    <a href="_create_resource_address">account::create_resource_address</a>(creator, b"<a href="farm.md#0xcafebabe_farm">farm</a>")
}
</code></pre>



</details>

<a name="0xcafebabe_farm_get_accrued_rewards"></a>

## Function `get_accrued_rewards`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_accrued_rewards">get_accrued_rewards</a>&lt;R&gt;(farmer: <b>address</b>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_accrued_rewards">get_accrued_rewards</a>&lt;R&gt;(farmer: <b>address</b>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): u64 {
    <a href="reward_vault.md#0xcafebabe_reward_vault_get_accrued_rewards">reward_vault::get_accrued_rewards</a>&lt;R&gt;(farmer, <a href="farm.md#0xcafebabe_farm">farm</a>)
}
</code></pre>



</details>

<a name="0xcafebabe_farm_get_staked"></a>

## Function `get_staked`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_staked">get_staked</a>&lt;R&gt;(farmer: &<b>address</b>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): <a href="">vector</a>&lt;<a href="_TokenId">token::TokenId</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_staked">get_staked</a>&lt;R&gt;(
    farmer: &<b>address</b>,
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>
): <a href="">vector</a>&lt;<a href="_TokenId">token::TokenId</a>&gt; <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a> {
    *<a href="_borrow">table::borrow</a>(&<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farmer">Farmer</a>&gt;(*farmer).staked, <a href="farm.md#0xcafebabe_farm">farm</a>)
}
</code></pre>



</details>

<a name="0xcafebabe_farm_is_registered"></a>

## Function `is_registered`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(farmer: &<b>address</b>, <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_is_registered">is_registered</a>&lt;R&gt;(
    farmer: &<b>address</b>,
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>
): bool <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>let</b> <a href="farm.md#0xcafebabe_farm">farm</a> = <b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>);
    <a href="_contains">vector::contains</a>(&<a href="farm.md#0xcafebabe_farm">farm</a>.farmer_handles, farmer)
}
</code></pre>



</details>

<a name="0xcafebabe_farm_is_whitelisted"></a>

## Function `is_whitelisted`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_is_whitelisted">is_whitelisted</a>&lt;R&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>, collection_name: <a href="_String">string::String</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_is_whitelisted">is_whitelisted</a>&lt;R&gt;(
    <a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>,
    collection_name: String
): bool <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>assert</b>!(<b>exists</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>), <a href="_not_found">error::not_found</a>(<a href="farm.md#0xcafebabe_farm_ERESOURCE_DNE">ERESOURCE_DNE</a>));
    <b>let</b> whitelisted_collections =
        &<b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).whitelisted_collections;
    <a href="_contains">table::contains</a>(whitelisted_collections, collection_name)
}
</code></pre>



</details>

<a name="0xcafebabe_farm_get_farmers"></a>

## Function `get_farmers`



<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_farmers">get_farmers</a>&lt;R&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): <a href="">vector</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="farm.md#0xcafebabe_farm_get_farmers">get_farmers</a>&lt;R&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>: <b>address</b>): <a href="">vector</a>&lt;<b>address</b>&gt; <b>acquires</b> <a href="farm.md#0xcafebabe_farm_Farm">Farm</a> {
    <b>borrow_global</b>&lt;<a href="farm.md#0xcafebabe_farm_Farm">Farm</a>&lt;R&gt;&gt;(<a href="farm.md#0xcafebabe_farm">farm</a>).farmer_handles
}
</code></pre>



</details>
