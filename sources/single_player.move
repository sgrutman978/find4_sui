module find_four::single_player {

    use find_four::find_four_game::{GameBoard, GamesTracker, recordLatestMoveCol, /*incrementGameNonce,*/ getNonce, initialize_game, addGameToTracker, getGameId, player_move, ai_move, setWinHandled};
    use sui::event;
    use find_four::profile_and_rank::{ProfileTable, get_trophies};
    // use find_four::math_utils::{log5};
    use find_four::FFIO::{reward_winner, FindFourAdminCap, Treasury, StakeObject, getStakedAmount};
    use sui::coin::{Self, Coin};
     use sui::sui::SUI;

    const AI_addy: address = @0x66696E64342E696F; // find4.io in hex
    const OneCoinNineDecimals: u64 = 1000000000;

    const LOG2_5_APPROX: u64 = 2;

    public struct SinglePlayerGameStartedEvent has copy, drop, store {
        game: address,
        p1: address
    }

    public struct SinglePlayerGameHumanPlayerMadeAMove has copy, drop, store {
        game: address,
        nonce: u64
    }

        use std::vector;

    // This function approximates log base 5 of y using the change of base formula
    // log5(y) = log2(y) / log2(5)
    public fun log5(y: u64): u64 {
        // First, we approximate log2(y)
        let log2_y = log2_approx(y);

        // Then, we approximate log2(5) which is a constant
         // Since log2(5) ≈ 2.32, we round down for simplicity

        // Finally, we divide log2(y) by log2(5)
        log2_y / LOG2_5_APPROX
    }

    // Helper function to approximate log base 2
    fun log2_approx(y: u64): u64 {
        let mut result = 0;
        let mut power = 1;
        // Find the highest power of 2 less than or equal to y
        while (power < y) {
            power = power * 2;
            result = result + 1;
        };
        // Since we've gone over if power > y, we decrease result by 1
        if (power > y) {
            result = result - 1;
        };
        result
    }

    public fun start_single_player_game3(gameTracker: &mut GamesTracker, mut payment: Coin<SUI>, ctx: &mut TxContext){
        pay_start_game_fee(payment, ctx);
        let gameId = initialize_game(ctx.sender(), AI_addy, 1, /*profile1, AI_addy,*/ ctx);
        addGameToTracker(ctx.sender(), gameId, gameTracker);
        let game_event = SinglePlayerGameStartedEvent { game: gameId, p1: ctx.sender() };
        event::emit(game_event);
    }

    public entry fun pay_start_game_fee(mut payment: Coin<SUI>, ctx: &mut TxContext) {
        let total_cost = (OneCoinNineDecimals/100)*2;
        assert!(coin::value(&payment) >= total_cost, 0); // Ensure enough payment
        // Split the payment coin into cost and remainder
        let cost = coin::split(&mut payment, total_cost, ctx);
        // Transfer cost to the presale organizer's address
        transfer::public_transfer(cost, @0x8418bb05799666b73c4645aa15e4d1ccae824e1487c01a665f51767826d192b7); // Replace with the address where you want SUI to go
        // Return any remainder to the buyer
        transfer::public_transfer(payment, tx_context::sender(ctx));
    }

    public fun player_make_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        player_move(game, column, ctx);
        // incrementGameNonce(game);
        recordLatestMoveCol(game, column);
        let human_move_event = SinglePlayerGameHumanPlayerMadeAMove { game: getGameId(game), nonce: getNonce(game) };
        event::emit(human_move_event);
    }

    //AI makes a move
    public fun ai_make_move(_: &FindFourAdminCap, game: &mut GameBoard, column: u64) {
        ai_move(game, column);
        recordLatestMoveCol(game, column);
        // incrementGameNonce(game);
    }

    public fun do_win_stuffs3(game: &mut GameBoard, pool: &mut Treasury, table: &ProfileTable, stakeObj: &StakeObject, ctx: &mut TxContext){
        if(!game.getWinHandled() && game.getGameType() == 1){
            let trophies = get_trophies(table, ctx.sender());
            let stakes1 = getStakedAmount(stakeObj)/100000;
            let stakes = 1 + ((20*100*stakes1)/(stakes1+(36000000*(OneCoinNineDecimals/100000))))/100;
            reward_winner(pool, (trophies*OneCoinNineDecimals*100*stakes), ctx); //profile1.getRewardAccount()
            setWinHandled(game, true);
        }
    }

    public fun do_win_stuffs2(game: &mut GameBoard, pool: &mut Treasury, table: &ProfileTable, ctx: &mut TxContext){
        if(!game.getWinHandled() && game.getGameType() == 1){
            let trophies = get_trophies(table, ctx.sender());
            reward_winner(pool, (trophies*OneCoinNineDecimals*100), ctx); //profile1.getRewardAccount()
            setWinHandled(game, true);
        }
    }


    

    























// DEPRECATED
    public fun do_win_stuffs(game: &mut GameBoard, pool: &mut Treasury, ctx: &mut TxContext){}
    public fun start_single_player_game(ctx: &mut TxContext){    }
    public fun start_single_player_game2(gameTracker: &mut GamesTracker, ctx: &mut TxContext){}

}