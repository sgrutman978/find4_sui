module find_four::old_AI {

    use std::debug;

    public(package) fun best_move(board: &vector<vector<u64>>): u8 {
        // This function would be more complex in a real scenario
        // Here's a placeholder for AI decision making
        let mut best_score = 10000; //(0-10000);
        let mut best_move = 0;
        let depth = 3; // Search depth for AI
        let mut col = 0;
        while (col < 7) {
            if (can_place(board, col)) {
                let score = minimax(&mut *board, depth, true, col);
                if (score > best_score) {
                    best_score = score;
                    best_move = col;
                }
            };
            col = col + 1;
        };
        return best_move
    }

    // Place piece in the column, return if successful
    fun place_piece(board: &mut vector<vector<u64>>, col: u8, player: u64): bool {
        if (col >= 7) { return false }; // Out of bounds
        let mut row = 5;
        while (row > 0) {
            if (*vector::borrow(vector::borrow(board, row), col as u64) == 0) {
                *vector::borrow_mut(vector::borrow_mut(board, row), col as u64) = player;
                return true
            };
            row = row - 1;
        };
        return false // Column is full
    }

    // Remove the top piece from a column
    fun remove_piece(board: &mut vector<vector<u64>>, col: u8) {
        if (col >= 7) return;
        let mut row = 0;
        while (row < 6) {
            if (*vector::borrow(vector::borrow(board, row), col as u64) != 0) {
                *vector::borrow_mut(vector::borrow_mut(board, row), col as u64) = 0;
                break
            };
            row = row + 1;
        }
    }

    // Check if a column can accept a piece
    fun can_place(board: &vector<vector<u64>>, col: u8): bool {
        if (col >= 7) return false;
        return *vector::borrow(vector::borrow(board, 0), col as u64) == 0
    }

    // Check if the game is over (win or full board)
    fun game_over(board: &vector<vector<u64>>): bool {
        return has_won(board, 1) || has_won(board, 2) || is_board_full(board)
    }

    // Check if the board is full (no empty spaces)
    fun is_board_full(board: &vector<vector<u64>>): bool {
        let mut col = 0;
        while (col < 7) {
            if (can_place(board, col)) return false;
            col = col + 1;
        };
        return true
    }

    // Check if a player has won
    fun has_won(board: &vector<vector<u64>>, player: u64): bool {
        // Check all possible winning lines
        return check_direction(board, player, 1, 0) ||  // horizontal
               check_direction(board, player, 0, 1) ||  // vertical
               check_direction(board, player, 1, 1) ||  // diagonal /
               check_direction(board, player, 1, 2)   // diagonal \ ---> 2 means -1, see lower code
    }

    fun check_direction(board: &vector<vector<u64>>, player: u64, row_step: u64, col_step: u64): bool {
        let mut row = 0;
        let mut col = 0;
        while (row < 6) {
            while (col < 7) {
                if (check_line(board, player, row, col, row_step, col_step)) {
                    return true
                };
                col = col + 1;
            };
            row = row + 1;
        };
        return false
    }

    fun check_line(board: &vector<vector<u64>>, player: u64, start_row: u64, start_col: u64, row_step: u64, col_step: u64): bool {
        let mut r = start_row;
        let mut c = start_col;
        // debug::print(&b"rxrxrxr");
        // debug::print(&r);
        // debug::print(&c);
        let mut i = 0;
        while (i < 4) {
            if (r < 0 || r >= 6 || c < 0 || c >= 7 || 
               board[r as u64][c as u64] != player) {
                return false
            };
            r = r + row_step;
            if (col_step == 2) {
                if(c > 0){
                    c = c - 1;
                }
            } else {
                c = c + col_step;
            };
            i = i + 1;
        };
        return true
    }

    fun minimax(board: &mut vector<vector<u64>>, depth: u8, is_maximizing: bool, col: u8): u64 {
        let player = if (is_maximizing) 2 else 1; // Assuming 2 is AI, 1 is human
        place_piece(board, col, player);
        
        if (game_over(board) || depth == 0) {
            let score = evaluate_position(board);
            remove_piece(board, col); // Undo the move to keep the board state unchanged for other calls
            return score
        };

        // if (is_maximizing) {
            let mut best_score = 10000;
            let mut next_col = 0;
            while (next_col < 3) {
                debug::print(&b"1");
                if (can_place(board, next_col)) {
                    debug::print(&b"2");
                    let score = minimax(board, depth - 1, false, next_col);
                    debug::print(&b"3");
                    best_score = max(best_score, score);
                };
                next_col = next_col + 1;
            };
            debug::print(&b"4");
            remove_piece(board, col);
            return best_score
        // }
        // } else {
        //     let mut best_score = 30000; // Start with a high score for minimizing player
        //     let mut next_col = 0;
        //     while(next_col < 7) {
        //         if (can_place(board, next_col)) {
        //             let score = minimax(board, depth - 1, true, next_col);
        //             best_score = min(best_score, score);
        //         };
        //         next_col = next_col + 1;
        //     };
        //     remove_piece(board, col);
        //     return best_score
        // }
    }

    fun evaluate_position(board: &vector<vector<u64>>): u64 {
        let mut score = 20000;
        let ai = 2;
        let human = 1;
        
        // Check for immediate wins or losses
        if (has_won(board, ai)) return 10000;
        if (has_won(board, human)) return (30000);

        // Evaluate based on potential lines (horizontal, vertical, diagonal)
        score = score + count_potential_lines(board, ai, 2) * 10;
        score = score + count_potential_lines(board, ai, 3) * 100;
        score = score - count_potential_lines(board, human, 2) * 10;
        score = score - count_potential_lines(board, human, 3) * 100;

        // Here, you might want to add more sophisticated heuristics like:
        // - Favor central columns
        // - Consider blocking the opponent's potential winning lines
        
        return score
    }

    // Helper functions (these need to be implemented as well)
    // fun has_won(board: &Vector<Vector<u8>>, player: u8): bool {
    //     // Implementation to check if 'player' has won
    // }

    // fun count_potential_lines(board: &vector<vector<u8>>, player: u8, count: u8): u64 {
    //     // Count how many lines (rows, columns, diagonals) with 'count' pieces from 'player'
    // }

    fun max(a: u64, b: u64): u64 {
        if (a > b) a else b
    }

    fun min(a: u64, b: u64): u64 {
        if (a < b) a else b
    }

    fun count_potential_lines(board: &vector<vector<u64>>, player: u64, count: u8): u64 {
        let mut potential_lines = 0;

        // Check horizontal lines
        let mut row = 0;
        let mut col = 0;
        while (row < 6) {
            while (col < (7-count+1)) {
                if (count_continuous(board, row, col, 1, 0, player, count)) {
                    potential_lines = potential_lines + 1;
                };
                col = col + 1;
            };
            row = row + 1;
        };

        // Check vertical lines
        row = 0;
        col = 0;
        while (row < (6-count+1)) {
            while (col < 7) {
                if (count_continuous(board, row, col, 0, 1, player, count)) {
                    potential_lines = potential_lines + 1;
                };
                col = col + 1;
            };
            row = row + 1;
        };

        row = 0;
        col = 0;
        // Check diagonal lines (positive slope: /)
        while (row < (6-count+1)) {
            while (col < (7-count+1)) {
                if (count_continuous(board, row, col, 1, 1, player, count)) {
                    potential_lines = potential_lines + 1;
                };
                col = col + 1;
            };
            row = row + 1;
        };

        row = (count-1);
        col = 0;
        // Check diagonal lines (negative slope: \)
        while (row < 6) {
            while (col < (7-count+1)) {
                if (count_continuous(board, row, col, 2, 1, player, count)) {
                    potential_lines = potential_lines + 1;
                };
                col = col + 1;
            };
            row = row + 1;
        };

        return potential_lines
    }

    fun count_continuous(board: &vector<vector<u64>>, row: u8, col: u8, row_step: u8, col_step: u8, player: u64, count: u8): bool {
        let mut continuous_count = 0;
        let mut current_row = row as u8;
        let mut current_col = col;

        while (continuous_count < count && current_row >= 0 && current_row < 6 && current_col >= 0 && current_col < 7) {
            if (*vector::borrow(vector::borrow(board, current_row as u64), current_col as u64) == player) {
                continuous_count = continuous_count + 1;
            } else {
                continuous_count = 0; // Reset if not the player's piece
            };
            
            if (continuous_count >= count) return true;
            if (current_row == 0) return false;
            
            if (row_step == 2) {
                current_row = current_row - 1;
            } else {
                current_row = current_row + row_step;
            };
            current_col = current_col + col_step;
        };
        return false
    }

}