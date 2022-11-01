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

    struct Coord has drop {
        x: u64,
        y: u64,
    }

    struct GameChangeEvent has key {
        res: address,
    }

    const EGAME_EXISTS: u64 = 0;
    const EACCOUNT_NOT_FOUND: u64 = 1;
    const ERESOURCE_DNE: u64 = 2;
    const EWAITING_OTHER_PLAYER: u64 = 3;
    const EINVALID_COORD: u64 = 4;

    public entry fun publish_game(player_one: &signer, player_two: address) {
        let empty_row: vector<Option<u8>> = vector[option::none(), option::none(), option::none()];
        let seeds = create_seeds(vector[signer::address_of(player_one), player_two]);

        let (acc, cap) = account::create_resource_account(player_one, seeds);

        let resource_addr = signer::address_of(&acc);

        assert!(!exists<Game>(resource_addr), EGAME_EXISTS);

        move_to(&acc, Game {
            turn: 1,
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
        ensures game.turn == 1;

        let post players = borrow_global<Game>(res).players;
        ensures players[0] == player_one;
    }

    public fun get_turn(game: address): u8 acquires Game {
        borrow_global<Game>(game).turn
    }

    public entry fun play(player: &signer, game: address, coord: Coord)
        acquires Game
    {
        let addr = signer::address_of(player);

        assert!(exists<Game>(game), error::invalid_argument(ERESOURCE_DNE));
        assert!(exists<GameChangeEvent>(addr), error::not_found(ERESOURCE_DNE));
        assert!(coord.x < 3 && coord.y < 3, EINVALID_COORD);
        assert!(is_player_turn(addr, game), EWAITING_OTHER_PLAYER);

        let players_ref = borrow_global<Game>(game).players;
        let (_, player_id) = vector::index_of(&players_ref, &addr);

        let turn_ref = &mut borrow_global_mut<Game>(game).turn;
        *turn_ref = *turn_ref + 1;

        let board_ref = borrow_global_mut<Game>(game).board;
        let y = vector::borrow_mut<vector<Option<u8>>>(&mut board_ref, coord.y);
        let x = vector::borrow_mut<Option<u8>>(y, coord.x);

        assert!(option::is_none(x), EINVALID_COORD);

        *x = option::some((player_id as u8));
    }

    spec play {
        pragma aborts_if_is_partial;

        modifies global<Game>(game);

        let addr = signer::address_of(player);
        let game_data = global<Game>(game);
        let turn = game_data.turn;

        aborts_if !exists<Game>(game);
        aborts_if !exists<GameChangeEvent>(addr);
        aborts_if coord.x >= 3 || coord.y >= 3;
        aborts_if !in_range(game_data.board, coord.y);
        aborts_if !in_range(game_data.board[coord.y], coord.x);
        aborts_if option::is_some(game_data.board[coord.y][coord.x]);
        aborts_if !contains(game_data.players, addr);
        aborts_if game_data.turn + 1 > MAX_U8;
        aborts_if game_data.turn == 0;


        let post turn_post = global<Game>(game).turn;
        ensures turn_post == turn + 1;
    }

    public fun current_player_index(game_addr: address): u64 acquires Game {
        let turn = borrow_global<Game>(game_addr).turn;
        (((turn - 1) % 2) as u64)
    }

    public fun is_player_turn(player: address, game_addr: address): bool acquires Game{
        let current = current_player_index(game_addr);
        let current_addr = vector::borrow(&borrow_global<Game>(game_addr).players, current);
        *current_addr == player
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

