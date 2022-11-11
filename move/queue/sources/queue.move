module MentaLabs::queue {
    use std::vector;
    use std::option::{Self, Option};

    struct Queue<T> has store, drop {
        inner: vector<T>,
    }

    public fun new<T>(): Queue<T> {
        Queue { inner: vector::empty<T>() }
    }

    public fun push_back<T>(queue: &mut Queue<T>, item: T) {
        vector::push_back(&mut queue.inner, item)
    }

    public fun pop_front<T>(queue: &mut Queue<T>): Option<T> {
        if (vector::is_empty(&queue.inner)) {
            return option::none()
        };
        option::some(vector::remove(&mut queue.inner, 0))
    }

    public fun peek<T: copy>(queue: &Queue<T>): Option<T> {
        if (vector::is_empty(&queue.inner)) {
            return option::none()
        };
        option::some(*vector::borrow(&queue.inner, 0))
    }

    public fun is_empty<T>(queue: &Queue<T>): bool {
        vector::is_empty(&queue.inner)
    }

    public fun length<T>(queue: &Queue<T>): u64 {
        vector::length(&queue.inner)
    }

    public fun destroy<T>(queue: Queue<T>) {
        let Queue { inner } = queue;
        vector::destroy_empty(inner)
    }

    #[test]
    fun queue() {
        let queue = new();
        assert!(is_empty(&queue), 0);
        assert!(length(&queue) == 0, 0);

        push_back(&mut queue, 1);
        push_back(&mut queue, 2);
        push_back(&mut queue, 3);
        assert!(!is_empty(&queue), 0);
        assert!(length(&queue) == 3, 0);

        assert!(pop_front(&mut queue) == option::some(1), 0);
        assert!(pop_front(&mut queue) == option::some(2), 0);
        assert!(pop_front(&mut queue) == option::some(3), 0);
        assert!(pop_front(&mut queue) == option::none(), 0);
        assert!(is_empty(&queue), 0);
        assert!(length(&queue) == 0, 0);

        // Variable is moved, so it cannot be used anymore.
        destroy(queue);
    }
}

