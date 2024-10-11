module find_four::multi_player {

    use sui::event;
    use find_four::find_four_game::{initialize_game};

    // Event to notify a successful pairing
    public struct PairingEvent has copy, drop, store {
        p1: address,
        p2: address,
        game: address
    }

    // Structure to hold waiting users
    public struct WaitingList has key {
        id: UID,
        tmp: u64,
        users: vector<address>, // Vector of user IDs waiting to be paired
    }

    // Add user to the waiting list
    public fun add_user_to_list(list: &mut WaitingList, user_id: address) {
        vector::push_back(&mut list.users, user_id);
    }

    fun init(ctx: &mut TxContext){
        let list = initialize_list( ctx);
        transfer::share_object(list);
    }

    // Initializes the waiting list
    fun initialize_list(ctx: &mut TxContext): WaitingList {
        WaitingList {
            id: object::new(ctx),
            tmp: 9,
            users: vector::empty<address>(),
        }
    }

    // Function to attempt pairing users and/or create a new multiplayer game
    public fun attempt_pairing(list: &mut WaitingList, ctx: &mut TxContext) {
        let list_len = vector::length(&list.users);
        // list.tmp = 7;
        //Check if there is at least one user waiting
        if (list_len > 0) {
            // Pair the incoming user with the first user in the queue
            let existing_user = vector::remove(&mut list.users, 0); // Remove the first user (FIFO order)
            let gameId = initialize_game(existing_user, 2, ctx);
            let pair_event = PairingEvent { p1: ctx.sender(), p2: existing_user, game: gameId };
            event::emit(pair_event);

            // Here, you can add logic to store or further process the `new_pair` object
        } else {
            // No existing users, add current user to the waiting list
            add_user_to_list(list, ctx.sender());
            // let pair_event = PairingEvent { p1: ctx.sender(), p2: ctx.sender(), game: ctx.sender() };
            // event::emit(pair_event);
        }
    }

}