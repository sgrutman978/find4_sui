module find_four::single_player {

    use find_four::find_four_game::{GameBoard, getBoard, initialize_game, getGameId, player_move, drop_disc};
    use sui::event;
    use find_four::AI::{best_move};

    const AI_addy: address = @0x66696E64342E696F; // find4.io in hex
    const EMPTY: u64 = 0;

    public struct AIMoveEvent has copy, drop, store {
        game: address
    }

        // Event to notify a successful pairing
    public struct SinglePlayerGameStartedEvent has copy, drop, store {
        game: address
    }

    public struct SinglePlayerGameHumanPlayerMadeAMove has copy, drop, store {
        game: address
    }

    public fun start_single_player_game(ctx: &mut TxContext){
        let gameId = initialize_game(AI_addy, 1, ctx);
        let game_event = SinglePlayerGameStartedEvent { game: gameId };
        event::emit(game_event);
    }

    public fun player_make_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        player_move(game, column, ctx);
        let human_move_event = SinglePlayerGameHumanPlayerMadeAMove { game: getGameId(game) };
        event::emit(human_move_event);
        // ai_make_move(game);
    }

    // AI makes a move
    // public(package) fun ai_make_move(game: &mut GameBoard) {
    //     let column = best_move(&game.getBoard()) as u64; //ai_choose_move(game);
    //     drop_disc(game, column);
    //     let ai_move_event = SinglePlayerGameStartedEvent { game: getGameId(game) };
    //     event::emit(ai_move_event);
    // }

    // fun ai_choose_move(game: &mut GameBoard): u64 {
    //     let mut valid_columns = vector::empty<u64>();
    //     let mut col = 0;
    //     while (col < 7) {
    //         if (getBoard(game)[0][col] == EMPTY) {
    //             vector::push_back(&mut valid_columns, col);
    //         };
    //         col = col + 1;
    //     };
    //     // Randomly choose a column from valid ones (for simplicity)
    //     let choice = 0; // Replace with actual random selection logic
    //     valid_columns[choice]
    // }

}