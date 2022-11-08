
<a name="0xcafebabe_queue"></a>

# Module `0xcafebabe::queue`



-  [Struct `Queue`](#0xcafebabe_queue_Queue)
-  [Function `new`](#0xcafebabe_queue_new)
-  [Function `push_back`](#0xcafebabe_queue_push_back)
-  [Function `pop_front`](#0xcafebabe_queue_pop_front)
-  [Function `peek`](#0xcafebabe_queue_peek)
-  [Function `is_empty`](#0xcafebabe_queue_is_empty)
-  [Function `length`](#0xcafebabe_queue_length)
-  [Function `destroy`](#0xcafebabe_queue_destroy)


<pre><code><b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a name="0xcafebabe_queue_Queue"></a>

## Struct `Queue`



<pre><code><b>struct</b> <a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt; <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>inner: <a href="">vector</a>&lt;T&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xcafebabe_queue_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_new">new</a>&lt;T&gt;(): <a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_new">new</a>&lt;T&gt;(): <a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt; {
    <a href="queue.md#0xcafebabe_queue_Queue">Queue</a> { inner: <a href="_empty">vector::empty</a>&lt;T&gt;() }
}
</code></pre>



</details>

<a name="0xcafebabe_queue_push_back"></a>

## Function `push_back`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_push_back">push_back</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<b>mut</b> <a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;, item: T)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_push_back">push_back</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<b>mut</b> <a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;, item: T) {
    <a href="_push_back">vector::push_back</a>(&<b>mut</b> <a href="queue.md#0xcafebabe_queue">queue</a>.inner, item)
}
</code></pre>



</details>

<a name="0xcafebabe_queue_pop_front"></a>

## Function `pop_front`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_pop_front">pop_front</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<b>mut</b> <a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;): <a href="_Option">option::Option</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_pop_front">pop_front</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<b>mut</b> <a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;): Option&lt;T&gt; {
    <b>if</b> (<a href="_is_empty">vector::is_empty</a>(&<a href="queue.md#0xcafebabe_queue">queue</a>.inner)) {
        <b>return</b> <a href="_none">option::none</a>()
    };
    <a href="_some">option::some</a>(<a href="_remove">vector::remove</a>(&<b>mut</b> <a href="queue.md#0xcafebabe_queue">queue</a>.inner, 0))
}
</code></pre>



</details>

<a name="0xcafebabe_queue_peek"></a>

## Function `peek`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_peek">peek</a>&lt;T: <b>copy</b>&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;): <a href="_Option">option::Option</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_peek">peek</a>&lt;T: <b>copy</b>&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;): Option&lt;T&gt; {
    <b>if</b> (<a href="_is_empty">vector::is_empty</a>(&<a href="queue.md#0xcafebabe_queue">queue</a>.inner)) {
        <b>return</b> <a href="_none">option::none</a>()
    };
    <a href="_some">option::some</a>(*<a href="_borrow">vector::borrow</a>(&<a href="queue.md#0xcafebabe_queue">queue</a>.inner, 0))
}
</code></pre>



</details>

<a name="0xcafebabe_queue_is_empty"></a>

## Function `is_empty`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_is_empty">is_empty</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_is_empty">is_empty</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;): bool {
    <a href="_is_empty">vector::is_empty</a>(&<a href="queue.md#0xcafebabe_queue">queue</a>.inner)
}
</code></pre>



</details>

<a name="0xcafebabe_queue_length"></a>

## Function `length`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_length">length</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_length">length</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: &<a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;): u64 {
    <a href="_length">vector::length</a>(&<a href="queue.md#0xcafebabe_queue">queue</a>.inner)
}
</code></pre>



</details>

<a name="0xcafebabe_queue_destroy"></a>

## Function `destroy`



<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_destroy">destroy</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: <a href="queue.md#0xcafebabe_queue_Queue">queue::Queue</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="queue.md#0xcafebabe_queue_destroy">destroy</a>&lt;T&gt;(<a href="queue.md#0xcafebabe_queue">queue</a>: <a href="queue.md#0xcafebabe_queue_Queue">Queue</a>&lt;T&gt;) {
    <b>let</b> <a href="queue.md#0xcafebabe_queue_Queue">Queue</a> { inner } = <a href="queue.md#0xcafebabe_queue">queue</a>;
    <a href="_destroy_empty">vector::destroy_empty</a>(inner)
}
</code></pre>



</details>
