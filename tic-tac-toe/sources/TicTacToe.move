module MentaLabs::TicTacToe {
    use std::option::{Self, Option};
    use std::vector;
    use std::signer;
    use std::bcs;
    use aptos_framework::account;
    use std::error;

    struct Game has key {
        turn: u8,
        board: vector<vector<Option<u8>>>,
        players: vector<address>,
        sign_cap: account::SignerCapability,
    }

    struct GameChangeEvent has key {
        res: address,
    }

    const EGAME_EXISTS: u64 = 0;
    const EACCOUNT_NOT_FOUND: u64 = 1;

    public entry fun publish_game(player_one: &signer, player_two: address) {
        let empty_row: vector<Option<u8>> = vector[option::none(), option::none(), option::none()];
        let seeds = create_seeds(vector[signer::address_of(player_one), player_two]);

        let (acc, cap) = account::create_resource_account(player_one, seeds);

        let resource_addr = signer::address_of(&acc);

        assert!(!exists<Game>(resource_addr), EGAME_EXISTS);

        move_to(&acc, Game {
            turn: 0,
            board: vector[empty_row, empty_row, empty_row],
            players: vector[
                signer::address_of(player_one),
                player_two,
            ],
            sign_cap: cap,
        });

        move_to(player_one, GameChangeEvent { res: signer::address_of(&acc) });
    }

    spec publish_game {
        let player_one = signer::address_of(player_one);

        let post res = global<GameChangeEvent>(player_one).res;
        let post game = global<Game>(res);
        ensures game.turn == 0;

        let post players = borrow_global<Game>(res).players;
        ensures players[0] == player_one;
    }

    fun create_seeds(addrs: vector<address>): vector<u8> {
        let ret: vector<u8> = vector::empty();
        let i = 0;
        while (i < vector::length(&addrs)) {
            let addr_bytes = bcs::to_bytes(vector::borrow(&addrs, i));
            vector::append(&mut ret, addr_bytes);
            i = i + 1;
        };

        ret
    }

    #[test(player_one = @0x111, player_two = @0x222)]
    public entry fun publishes_game(player_one: signer, player_two: signer) acquires Game {
        let player_one_addr = signer::address_of(&player_one);
        let player_two_addr = signer::address_of(&player_two);

        let seeds = create_seeds(vector[player_one_addr, player_two_addr]);
        let game = account::create_resource_address(&player_one_addr, seeds);
        assert!(!exists<Game>(game), EGAME_EXISTS);

        publish_game(&player_one, player_two_addr);

        assert!(exists<GameChangeEvent>(player_one_addr), error::not_found(EACCOUNT_NOT_FOUND));
        assert!(exists<Game>(game), error::not_found(EACCOUNT_NOT_FOUND));
        assert!(borrow_global<Game>(game).turn == 0, 1);
    }

    #[test(player_one = @0x111, player_two = @0x222)]
    #[expected_failure(abort_code = 524303)]
    public entry fun cant_start_twice(player_one: signer, player_two: signer) {
        let player_two_addr = signer::address_of(&player_two);
        publish_game(&player_one, player_two_addr);
        publish_game(&player_one, player_two_addr);
    }
}

