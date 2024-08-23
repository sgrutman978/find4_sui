
// #[test_only]
// module my_first_package::my_first_package_tests {
//     use my_first_package::my_module::Sword;
//     // uncomment this line to import the module
//     // use my_first_package::my_first_package;

//     const ENotImplemented: u64 = 0;

//     #[test]
//     fun test_my_first_package() {
//         // pass
//     }



//     #[test, expected_failure(abort_code = ::my_first_package::my_first_package_tests::ENotImplemented)]
//     fun test_my_first_package_fail() {
//         abort ENotImplemented
//     }  
// }

#[test_only]
module find_four::find_four_tests {
    use sui::test_scenario::{Self};//, Scenario};
    use find_four::find_four_game::{initialize_game, player_move, check_for_win_in_tests, print_board};
    const P1: address = @0xCAFE;
    use std::debug;
    // use find_four::game::{GameBoard};

   #[test]
fun test_game() {
    // Create test addresses representing users
    
    // let p2 = @0xFACE;

    let mut scenario_val = test_scenario::begin(P1);
    let scenario = &mut scenario_val;
    let mut game = initialize_game(scenario.ctx());
    game.player_move(2);
    print_board(&mut game);
    transfer::public_transfer(game, @0xDEAD);
    scenario_val.end();
}

    #[test]
    public fun test_check_for_win_horizontal() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1);
        let scenario = &mut scenario_val;
        let mut game = initialize_game(scenario.ctx());

        // Simulate a horizontal win for Player 1
        player_move(&mut game, 0);  // P1
        player_move(&mut game, 0);  // P2
        player_move(&mut game, 1);  // P1
        player_move(&mut game, 0);  // P2
        player_move(&mut game, 2);  // P1
        player_move(&mut game, 0);  // P2
        player_move(&mut game, 3);  // P1

        print_board(&mut game);
        // Check for a win
        let has_won = check_for_win_in_tests(&mut game, 1);
        assert!(has_won, 1);
        transfer::public_transfer(game, @0xDEAD);
        scenario_val.end();
    }

    #[test]
    public fun test_check_for_win_vertical() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1);
        let scenario = &mut scenario_val;
        let mut game = initialize_game(scenario.ctx());

        // Simulate a vertical win for Player 2
        player_move(&mut game, 0);  // P1
        player_move(&mut game, 1);  // P2
        player_move(&mut game, 0);  // P1
        player_move(&mut game, 1);  // P2
        player_move(&mut game, 0);  // P1
        player_move(&mut game, 1);  // P2
        player_move(&mut game, 0);  // P1

        // Check for a win
        let has_won = check_for_win_in_tests(&mut game, 1);
        debug::print(&has_won);
        print_board(&mut game);
        assert!(has_won, 1);
        transfer::public_transfer(game, @0xDEAD);
        scenario_val.end();
    }

    #[test]
    public fun test_check_for_win_diagonal() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1);
        let scenario = &mut scenario_val;
        let mut game = initialize_game(scenario.ctx());

        // Simulate a diagonal win for Player 1
        player_move(&mut game, 0);  // P1
        player_move(&mut game, 1);  // P2
        player_move(&mut game, 1);  // P1
        player_move(&mut game, 2);  // P2
        player_move(&mut game, 2);  // P1
        player_move(&mut game, 3);  // P2
        player_move(&mut game, 2);  // P1
        player_move(&mut game, 3);  // P2
        player_move(&mut game, 3);  // P1
        player_move(&mut game, 5);  // P2
        player_move(&mut game, 3);  // P1

        print_board(&mut game);
        // Check for a win
        let has_won = check_for_win_in_tests(&mut game, 1);
        assert!(has_won, 1);
        transfer::public_transfer(game, @0xDEAD);
        scenario_val.end();
    }


}