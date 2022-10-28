module MentaLabs::TicTacToe {
    use std::option::{Self, Option};
    use std::vector;
    use std::signer;
    use std::bcs;
    use aptos_framework::account;

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

    public entry fun publish_game(player_one: &signer, player_two: address) {
        let empty_row: vector<Option<u8>> = vector[option::none(), option::none(), option::none()];
        let seeds = create_seeds(vector[signer::address_of(player_one), player_two]);

        let (acc, cap) = account::create_resource_account(player_one, seeds);

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
        let addr = signer::address_of(player_one);

        let post res = global<GameChangeEvent>(addr).res;

        let post game = global<Game>(res);
        ensures game.turn == 0;

        let post players = borrow_global<Game>(res).players;
        ensures players[0] == addr;
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
}

