module find_four::find_four_game {
    use std::debug;
    use sui::event;
    // use find_four::multiplayer::{}

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
        p2: address,
        gameType: u64 // 1 = against AI (singleplayer), 2 = multiplayer
    }

    public fun getBoard(game: &mut GameBoard): vector<vector<u64>>{
        game.board
    }

    public fun getGameId(game: &mut GameBoard): address {
        let addy = object::uid_to_address(&game.id);
        addy
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

    // Function for a human player to make a move
    public(package) fun player_move(game: &mut GameBoard, column: u64, ctx: &mut TxContext) {
        assert!(!game.is_game_over, 0);
        assert!((game.current_player == P1 && ctx.sender() == game.p1) || (game.current_player == P2 && ctx.sender() == game.p2), 1);
        drop_disc(game, column);
    }

    public fun check_for_win_in_tests(game: &mut GameBoard, player: u64): bool{
        check_for_win(&game.board, player)
    }

    // Helper function to create an empty board
    public(package) fun create_empty_board(): vector<vector<u64>> {
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
    public(package) fun initialize_game(p2: address, gameType: u64, ctx: &mut TxContext) : address {
        let uid = object::new(ctx);
        let game_addy = object::uid_to_address(&uid);
        let game = GameBoard {
            id: uid,
            board: create_empty_board(),
            current_player: P1,
            is_game_over: false,
            p1: ctx.sender(),
            p2: p2,
            gameType: gameType

        };
        transfer::share_object(game);
        game_addy
    } 

        // Drop a disc into a column
    public(package) fun drop_disc(game: &mut GameBoard, column: u64) {
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

    public fun change_element(matrix: &mut vector<vector<u64>>, i: u64, j: u64, new_value: u64) {
        // Borrow the inner vector at index `i` from the outer vector `matrix`
        let inner_vec = vector::borrow_mut(matrix, i);
        // Borrow the element at index `j` in the `inner_vec` and update it
        *vector::borrow_mut(inner_vec, j) = new_value;
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

}
