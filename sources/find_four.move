module find_four::find_four_game {
    use std::debug;

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
    public fun initialize_game(ctx: &mut TxContext) {
        let game = GameBoard {
            id: object::new(ctx),
            board: create_empty_board(),
            current_player: P1,
            is_game_over: false,
        };
        transfer::share_object(game);
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
                break;
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
    public fun player_move(game: &mut GameBoard, column: u64) {
        assert!(!game.is_game_over, 0);
        debug::print(&b"mehhhhhh");
        drop_disc(game, column);
    }

    // Function to let the AI opponent make a move
    public fun ai_move(game: &mut GameBoard) {
        assert!(!game.is_game_over, 0);
        ai_make_move(game);
    }
}

// module my_first_package::my_module {
//     use std::hash;

//     const EInvalidShoot: u64 = 0;

//     public struct GameParticipant has key, store {
//         id: UID,
//         game_addy: address
//     }

//     public struct RPS_Game has key {
//         id: UID,
//         status: u8, //current turn, TODO check for your turn
//         games: u8,
//         shoot1: vector<u8>,
//         // dummy: vector<u8>,
//         shoot2: u8,
//         who_shoots_first: u8,
//         proved_first_shoot: u8,
//         player1: address,
//         player2: address,
//         wins1: u8,
//         wins2: u8,
//         playTo: u8,
//         ties: u8,
//         // hash: vector<u8>,
//     }

//     public fun new_game(/*player1_profile: &mut Profile, player2_profile: &mut Profile,*/ player1_addy: address, player2_addy: address, ctx: &mut TxContext) {
//         let uid = object::new(ctx);
//         let game_addy = object::uid_to_address(&uid);
//         let game2 = RPS_Game {
//             id: uid,
//             status: 0,
//             games: 0,
//             shoot1: b"",
//             // dummy: b"",
//             shoot2: 0,
//             who_shoots_first: 1,
//             proved_first_shoot: 0,
//             wins1: 0,
//             wins2: 0,
//             player1: player1_addy, //ctx.sender(), 
//             player2: player2_addy,
//             playTo: 0,
//             ties: 0,
//             // hash: b""
//         };
//         transfer::share_object(game2);
//         let gp1 = create_game_participant(game_addy, ctx);
//         let gp2 = create_game_participant(game_addy, ctx);
//         transfer::transfer(gp1, player1_addy);
//         transfer::transfer(gp2, player2_addy);
//     }

//     public fun create_game_participant(game_addy: address, ctx: &mut TxContext) : GameParticipant{
//         GameParticipant {
//             id: object::new(ctx),
//             game_addy: game_addy,
//         }
//     }

//     public fun do_1st_shoot(game: &mut RPS_Game, shoot: vector<u8>, ctx: &mut TxContext) {
//         assert!(game.status == 0 , EInvalidShoot);
//         if ((game.player1 == ctx.sender() && game.who_shoots_first == 1) || (game.player2 == ctx.sender() && game.who_shoots_first == 2)) {
//             game.shoot1 = shoot;
//             game.status = 1;
//         };
//     }

//     public fun do_2nd_shoot(game: &mut RPS_Game, shoot: u8, ctx: &mut TxContext) {
//         assert!(shoot < 4 && shoot > 0 && game.status == 1 , EInvalidShoot);
//         if ((game.who_shoots_first == 1 && game.player2 == ctx.sender()) || (game.who_shoots_first == 2 && game.player1 == ctx.sender())) {
//             game.shoot2 = shoot;
//             game.status = 2;
//         };
//     }

//     public fun prove_1st_shoot(shoot: u8, game: &mut RPS_Game, salt: vector<u8>, ctx: &mut TxContext) {
//         assert!(shoot < 4 && shoot > 0 && game.status == 2 , EInvalidShoot);
//         let mut combined = salt;
//         combined.push_back<u8>((shoot+48));
//         // game.hash = combined;
//         // let hash = hash::sha2_256(combined);
//         let hash = sha256_to_hex(combined);
//         // game.dummy = hash;
//         assert!(hash == game.shoot1 , EInvalidShoot);
//         game.proved_first_shoot = shoot;
//         game.check_for_win();
//     }

//     public fun hard_reset(game: &mut RPS_Game, ctx: &mut TxContext) {
//         game.shoot1 = b"";
//         game.shoot2 = 0;
//         game.who_shoots_first = 1;
//         game.proved_first_shoot = 0;
//         game.status = 0;
//     }

//     fun check_for_win(game: &mut RPS_Game){
//         // 1 = rock, 2 = paper, 3 = scissors
//         let gs1 = game.proved_first_shoot;
//         let gs2 = game.shoot2;
//         if (gs1 != 0 && gs2 != 0){
//             if (gs1 != gs2){
//                 if((game.who_shoots_first == 1 && ((gs1 == 1 && gs2 == 3) || (gs1 == 2 && gs2 == 1) || (gs1 == 3 && gs2 == 2))) ||
//                     (game.who_shoots_first == 2 && ((gs1 == 3 && gs2 == 1) || (gs1 == 1 && gs2 == 2) || (gs1 == 2 && gs2 == 3)))){
//                     game.wins1 = game.wins1 + 1;
//                 } else {
//                     game.wins2 = game.wins2 + 1;
//                 }
//                 // if(game.who_shoots_first == 1){
//                 //     if ((gs1 == 1 && gs2 == 3) || (gs1 == 2 && gs2 == 1) || (gs1 == 3 && gs2 == 2)){
//                 //         game.wins1 = game.wins1 + 1;
//                 //     } else {
//                 //         game.wins2 = game.wins2 + 1;
//                 //     };
//                 // } else {
//                 //     if ((gs1 == 1 && gs2 == 3) || (gs1 == 2 && gs2 == 1) || (gs1 == 3 && gs2 == 2)){
//                 //         game.wins2 = game.wins2 + 1;
//                 //     } else {
//                 //         game.wins1 = game.wins1 + 1;
//                 //     };
//                 // }
//             }else{
//                 game.ties = game.ties + 1;
//             };
//             game.shoot1 = b"";
//             game.shoot2 = 0;
//             game.status = 0;
//             if (game.who_shoots_first == 1){
//                 game.who_shoots_first = 2;
//             } else {
//                 game.who_shoots_first = 1;
//             };
//             game.games = game.games + 1;
//         };
//     }

//     // Accessors
//     public fun wins1(game: &RPS_Game): u8 { game.wins1 }
//     public fun wins2(game: &RPS_Game): u8 { game.wins2 }


//     public fun byte_to_hex(byte: u8): vector<u8> {
//         let hex_chars = b"0123456789abcdef";
//         let high_nibble = (byte >> 4) & 0x0F;
//         let low_nibble = byte & 0x0F;
//         let high_char = *vector::borrow(&hex_chars, high_nibble as u64);
//         let low_char = *vector::borrow(&hex_chars, low_nibble as u64);
//         let mut result = vector::empty<u8>();
//         vector::push_back(&mut result, high_char);
//         vector::push_back(&mut result, low_char);
//         result
//     }

//     public fun bytes_to_hex(bytes: vector<u8>): vector<u8> {
//         let mut hex_string = vector::empty<u8>();
//         let len = vector::length(&bytes);
//         let mut i = 0;
//         while (i < len) {
//             let byte = *vector::borrow(&bytes, i);
//             let hex_byte = byte_to_hex(byte);
//             vector::append(&mut hex_string, hex_byte);
//             i = i + 1;
//         };
//         hex_string
//     }

//     public fun sha256_to_hex(input: vector<u8>): vector<u8> {
//         let hash = std::hash::sha2_256(input);
//         bytes_to_hex(hash)
//     }


// }
