module find_four::find_four_game {
    use std::debug;
    use sui::event;

    // Enums for representing the players and board slots
    // public enum Player {
    //     P1,
    //     P2,
    // }

    const EMPTY: u64 = 0;
    const P1: u64 = 1;
    const P2: u64 = 2;

    // Struct for representing the game board
    public struct GameBoard has key, store {
        id: UID,
        board: vector<vector<u64>>, // 6 rows by 7 columns
        current_player: u64,
        is_game_over: bool,
        p1: address,
        p2: address
    }

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

    // Add user to the waiting list
    public fun add_user_to_list(list: &mut WaitingList, user_id: address) {
        // let list = borrow_global_mut<SharedList>(list_id);
        // let listRef = vector::borrow_mut(&mut list, n);
        vector::push_back(&mut list.users, user_id);
        
        // Assign the new value to the nth element
        // *elem_ref = new_value;
    }

        // Function to attempt pairing users
    public fun attempt_pairing(list: &mut WaitingList, ctx: &mut TxContext) {
        let list_len = vector::length(&list.users);
        // list.tmp = 7;
        //Check if there is at least one user waiting
        if (list_len > 0) {
            // Pair the incoming user with the first user in the queue
            let existing_user = vector::remove(&mut list.users, 0); // Remove the first user (FIFO order)
            let gameId = initialize_game(existing_user, ctx);
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

    // Helper function to create an empty board
    fun create_empty_board(): vector<vector<u64>> {
        let mut board = vector::empty<vector<u64>>();
        let mut r: u64 = 0;
        while (r < 6) {
            let mut row = vector::empty<u64>();
            let mut c: u64 = 0;
            while (c < 7) {
                vector::push_back(&mut row, EMPTY);
                c = c + 1;
            };
            vector::push_back(&mut board, row);
            r = r + 1;
        };
        board
    }

    // Initialize a new game
    fun initialize_game(p2: address, ctx: &mut TxContext) : address {
        let uid = object::new(ctx);
        let game_addy = object::uid_to_address(&uid);
        let game = GameBoard {
            id: uid,
            board: create_empty_board(),
            current_player: P1,
            is_game_over: false,
            p1: ctx.sender(),
            p2: p2
        };
        transfer::share_object(game);
        game_addy
    } 

    public fun change_nth_element(mut v: vector<u64>, n: u64, new_value: u64) {
        // Get a mutable reference to the nth element
        let elem_ref = vector::borrow_mut(&mut v, n);
        // Assign the new value to the nth element
        *elem_ref = new_value;
    }

    public fun print_board(game: &mut GameBoard) {
        // debug::print(&game.board);
        // needs to be printed upside down
        let mut row = 5;
        while (row >= 0) {
            debug::print(&game.board[row]);
            if (row == 0){
                break
            };
            row = row - 1;
        }
    }

        // Drop a disc into a column
    fun drop_disc(game: &mut GameBoard, column: u64) {
        assert!(column < 7, 0);
        debug::print(&b"jsjsjsj");
        let mut row = 0;
        while (row < 6) {
            if (game.board[row][column] == EMPTY) {
                change_element(&mut game.board, row, column, game.current_player);
                // change_nth_element(game.board[row], column, game.current_player);
                debug::print(&b"jsj");
                if (check_for_win(&game.board, game.current_player)) {
                    game.is_game_over = true;
                };
                if (game.current_player == P1){
                    game.current_player = P2;
                }else{
                    game.current_player = P1;
                };
                return
            };
            row = row + 1;
        };
        // abort!(1); // Column is full
    }

    fun change_element(matrix: &mut vector<vector<u64>>, i: u64, j: u64, new_value: u64) {
        // Borrow the inner vector at index `i` from the outer vector `matrix`
        let inner_vec = vector::borrow_mut(matrix, i);

        // Borrow the element at index `j` in the `inner_vec` and update it
        *vector::borrow_mut(inner_vec, j) = new_value;
    }

    public fun check_for_win_in_tests(game: &mut GameBoard, player: u64): bool{
        check_for_win(&game.board, player)
    }

    // Check for a win (simplified for brevity)
    fun check_for_win(board: &vector<vector<u64>>, player: u64): bool {
         let rows = 6;
        let cols = 7;
        let mut row = 0;
        let mut col = 0;

        // Check horizontal win
        let _col = col;
        while (row < rows) {
            col = 0;
            while(col < (cols - 3)) {
                if (board[row][col] == player &&
                   board[row][col + 1] == player &&
                   board[row][col + 2] == player &&
                   board[row][col + 3] == player) {
                    return true
                };
                col = col + 1;
            };
            row = row + 1;
        };

        // Check vertical win
        col = 0;
        while (col < cols) {
            row = 0;
            while(row < (rows - 3)) {
                if (board[row][col] == player &&
                   board[row + 1][col] == player &&
                   board[row + 2][col] == player &&
                   board[row + 3][col] == player) {
                    return true
                };
                row = row + 1;
            };
            col = col + 1;
        };

        // Check diagonal win (bottom-left to top-right)
        col = 0;
        row = 0;
        while (row < (rows - 3)) {
            while (col < (cols - 3)) {
                if (board[row][col] == player &&
                   board[row + 1][col + 1] == player &&
                   board[row + 2][col + 2] == player &&
                   board[row + 3][col + 3] == player) {
                    return true
                };
                col = col + 1;
            };
            row = row + 1;
        };

        col = 0;
        row = 3;
        // Check diagonal win (top-left to bottom-right)
        while (row < rows) {
            while (col < (cols - 3)) {
                if (board[row][col] == player &&
                   board[row - 1][col + 1] == player &&
                   board[row - 2][col + 2] == player &&
                   board[row - 3][col + 3] == player) {
                    return true
                };
                col = col + 1;
            };
            row = row + 1;
        };

        // No win found
        false
    }

        // AI chooses a random valid column
    fun ai_choose_move(game: &GameBoard): u64 {
        let mut valid_columns = vector::empty<u64>();
        let mut col = 0;
        while (col < 7) {
            if (game.board[0][col] == EMPTY) {
                vector::push_back(&mut valid_columns, col);
            };
            col = col + 1;
        };

        // Randomly choose a column from valid ones (for simplicity)
        let choice = 0; // Replace with actual random selection logic
        valid_columns[choice]
    }

    // AI makes a move
    public fun ai_make_move(game: &mut GameBoard) {
        let column = ai_choose_move(game);
        drop_disc(game, column);
    }

        // Function for a human player to make a move
    public fun player_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        assert!(!game.is_game_over, 0);
        debug::print(&b"mehhhhhh");
        assert!((game.current_player == P1 && ctx.sender() == game.p1) || (game.current_player == P2 && ctx.sender() == game.p2), 1);
        drop_disc(game, column);
    }

    // Function to let the AI opponent make a move
    public fun ai_move(game: &mut GameBoard) {
        assert!(!game.is_game_over, 0);
        ai_make_move(game);
    }
}
