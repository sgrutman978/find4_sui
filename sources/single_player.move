module find_four::single_player {

    use find_four::find_four_game::{GameBoard, incrementGameNonce, getNonce, initialize_game, getGameId, player_move, ai_move, setWinHandled};
    use sui::event;
    use find_four::profile_and_rank::{Profile};
    use find_four::FFIO::{reward_winner, FindFourAdminCap, Treasury};

    const AI_addy: address = @0x66696E64342E696F; // find4.io in hex

    public struct SinglePlayerGameStartedEvent has copy, drop, store {
        game: address,
        p1: address
    }

    public struct SinglePlayerGameHumanPlayerMadeAMove has copy, drop, store {
        game: address,
        nonce: u64
    }

    public fun start_single_player_game(/*profile1: address,*/ ctx: &mut TxContext){
        let gameId = initialize_game(ctx.sender(), AI_addy, 1, /*profile1, AI_addy,*/ ctx);
        let game_event = SinglePlayerGameStartedEvent { game: gameId, p1: ctx.sender() };
        event::emit(game_event);
    }

    public fun player_make_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        player_move(game, column, ctx);
        incrementGameNonce(game);
        let human_move_event = SinglePlayerGameHumanPlayerMadeAMove { game: getGameId(game), nonce: getNonce(game) };
        event::emit(human_move_event);
    }

    //AI makes a move
    public fun ai_make_move(_: &FindFourAdminCap, game: &mut GameBoard, column: u64) {
        ai_move(game, column);
        incrementGameNonce(game);
    }

    public fun do_win_stuffs(game: &mut GameBoard, pool: &mut Treasury, ctx: &mut TxContext){
        if(!game.getWinHandled() && game.getGameType() == 1){
            reward_winner(pool, 1, ctx); //profile1.getRewardAccount()
            setWinHandled(game, true);
        }
    }

}