module find_four::single_player {

    use find_four::find_four_game::{GameBoard, incrementNonce, getNonce, initialize_game, getGameId, player_move, ai_move, FindFourAdminCap};
    use sui::event;
    // use find_four::profile_and_rank::{Profile};

    const AI_addy: address = @0x66696E64342E696F; // find4.io in hex

    public struct SinglePlayerGameStartedEvent has copy, drop, store {
        game: address
    }

    public struct SinglePlayerGameHumanPlayerMadeAMove has copy, drop, store {
        game: address,
        nonce: u64
    }

    public fun start_single_player_game(profile1: address, ctx: &mut TxContext){
        let gameId = initialize_game(ctx.sender(), AI_addy, 1, profile1, AI_addy, ctx);
        let game_event = SinglePlayerGameStartedEvent { game: gameId };
        event::emit(game_event);
    }

    public fun player_make_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        player_move(game, column, ctx);
        incrementNonce(game);
        let human_move_event = SinglePlayerGameHumanPlayerMadeAMove { game: getGameId(game), nonce: getNonce(game) };
        event::emit(human_move_event);
        // ai_make_move(game);
    }

    //AI makes a move
    public fun ai_make_move(_: &FindFourAdminCap, game: &mut GameBoard, column: u64) {
        ai_move(game, column);
        incrementNonce(game);
    }

}