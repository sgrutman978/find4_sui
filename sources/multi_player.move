module find_four::multi_player {

    use sui::event;
    use find_four::find_four_game::{initialize_game, GameBoard, player_move, FindFourAdminCap};
    use find_four::profile_and_rank::{Profile};

    // Event to notify a successful pairing
    public struct PairingEvent has copy, drop, store {
        p1: address,
        p2: address,
        game: address
    }

    public struct AddToListEvent has copy, drop, store {
        addy: address,
        profileAddy: address,
        points: u64,
        nonce: u64
    }

    public struct FFIO_Nonce has key {
        id: UID,
        nonce: u64
    }

    // Structure to hold waiting users
    // public struct WaitingList has key {
    //     id: UID,
    //     // tmp: u64,
    //     users: vector<address>, // Vector of user IDs waiting to be paired
    // }

    // Add user to the waiting list
    // public fun add_user_to_list(list: &mut WaitingList, user_id: address) {
    //     vector::push_back(&mut list.users, user_id);
    // }

    fun init(ctx: &mut TxContext){
        // let list = initialize_list( ctx);
        // transfer::share_object(list);
        let nonce_tracker = initialize_nonce_tracker(ctx);
        transfer::share_object(nonce_tracker);
    }

    fun initialize_nonce_tracker(ctx: &mut TxContext): FFIO_Nonce {
        FFIO_Nonce {
            id: object::new(ctx),
            nonce: 0
        }
    }

    // Initializes the waiting list
    // fun initialize_list(ctx: &mut TxContext): WaitingList {
    //     WaitingList {
    //         id: object::new(ctx),
    //         // tmp: 9,
    //         users: vector::empty<address>(),
    //     }
    // }

    public(package) fun incrementNonce(the_ffio_nonce: &mut FFIO_Nonce) {
        the_ffio_nonce.nonce = the_ffio_nonce.nonce + 1;
    }

    public fun player_make_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        player_move(game, column, ctx);
    }

    public fun add_to_list(addy: address, profileAddy: address, points: u64, nonce: u64){
        let add_to_List_event = AddToListEvent { addy: addy, profileAddy: profileAddy, points: points, nonce: nonce };
        event::emit(add_to_List_event);
    }

    // public fun second_player_make_first_move(game: &mut GameBoard, pointsObjAddy: address,  column: u64, ctx: &mut TxContext) {
    //     setPlayer2PointsStuff(game, pointsObjAddy);
    //     player_move(game, column, ctx);
    // }

    // Function to attempt pairing users and/or create a new multiplayer game
    public fun attempt_pairing(_: &FindFourAdminCap, /*p1Index: u64, p2Index: u64, */p1: address, p2: address, profile1: address, profile2: address, ctx: &mut TxContext) {
        // let list_len = vector::length(&list.users);
        // list.tmp = 7;
        //Check if there is at least one user waiting
        // if (list_len > 0) {
            // Pair the incoming user with the first user in the queue
            // vector::remove(&mut list.users, p1Index);
            // vector::remove(&mut list.users, p2Index); // Remove the first user (FIFO order)
            let gameId = initialize_game(p1, p2, 2, profile1, profile2, ctx);
            let pair_event = PairingEvent { p1: p1, p2: p2, game: gameId };
            event::emit(pair_event);
        // } else {
        //     // No existing users, add current user to the waiting list
        //     add_user_to_list(list, ctx.sender());
        // }
    }

}