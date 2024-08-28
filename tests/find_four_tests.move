
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
    use sui::test_scenario::{Self, Scenario};
    use find_four::find_four_game::{GameBoard, initialize_game, player_move, check_for_win_in_tests, print_board};
    use std::debug;

    const P1_addy: address = @0xCAFE;
    const P2_addy: address = @0xFACE;
    // use find_four::game::{GameBoard};

   #[test]
fun test_game() {
    // Create test addresses representing users
    
    // let p2 = @0xFACE;

    let mut scenario_val = test_scenario::begin(P1_addy);
    let scenario = &mut scenario_val;
    initialize_game(P2_addy, scenario.ctx());
    scenario.next_tx(P1_addy);
        {
            let mut game_val = scenario.take_shared<GameBoard>();
            let game = &mut game_val;
            player_move(game, 2, scenario.ctx());
            print_board(game);
            // transfer::public_transfer(game_val, @0xDEAD);
            test_scenario::return_shared(game_val);
        };

    scenario_val.end();
}

    #[test]
    public fun test_check_for_win_horizontal() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1_addy);
        let scenario: &mut Scenario = &mut scenario_val;
        initialize_game(P2_addy, scenario.ctx());

        // Simulate a horizontal win for Player 1
        make_player_move_for_tests(scenario, 0, P1_addy);
        make_player_move_for_tests(scenario, 0, P2_addy);
        make_player_move_for_tests(scenario, 1, P1_addy);
        make_player_move_for_tests(scenario, 0, P2_addy);
        make_player_move_for_tests(scenario, 2, P1_addy);
        make_player_move_for_tests(scenario, 0, P2_addy);
        make_player_move_for_tests(scenario, 3, P1_addy);

        scenario.next_tx(P1_addy);
        {
            let mut game_val = scenario.take_shared<GameBoard>();
            let game = &mut game_val;
            print_board(game);
            // Check for a win
            let has_won = check_for_win_in_tests(game, 1);
            assert!(has_won, 1);
            // transfer::public_transfer(game_val, @0xDEAD);
            test_scenario::return_shared(game_val);
        };
        scenario_val.end();
    }

    #[test]
    public fun test_check_for_win_vertical() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1_addy);
        let scenario = &mut scenario_val;
        initialize_game(P2_addy, scenario.ctx());

        // Simulate a vertical win for Player 2
        make_player_move_for_tests(scenario, 0, P1_addy);
        make_player_move_for_tests(scenario, 1, P2_addy);
        make_player_move_for_tests(scenario, 0, P1_addy);
        make_player_move_for_tests(scenario, 1, P2_addy);
        make_player_move_for_tests(scenario, 0, P1_addy);
        make_player_move_for_tests(scenario, 1, P2_addy);
        make_player_move_for_tests(scenario, 2, P1_addy);
        make_player_move_for_tests(scenario, 1, P2_addy);

        scenario.next_tx(P1_addy);
        {
            let mut game_val = scenario.take_shared<GameBoard>();
            let game = &mut game_val;
            // Check for a win
            let has_won = check_for_win_in_tests(game, 2);
            debug::print(&has_won);
            print_board(game);
            assert!(has_won, 1);
            test_scenario::return_shared(game_val);
        };
        scenario_val.end();
    }

    #[test]
    public fun test_check_for_win_diagonal() {
        // Initialize a new game
        let mut scenario_val = test_scenario::begin(P1_addy);
        let scenario = &mut scenario_val;
        initialize_game(P2_addy, scenario.ctx());

            // Simulate a diagonal win for Player 1
        make_player_move_for_tests(scenario, 0, P1_addy);
        make_player_move_for_tests(scenario, 1, P2_addy);
        make_player_move_for_tests(scenario, 1, P1_addy);
        make_player_move_for_tests(scenario, 2, P2_addy);
        make_player_move_for_tests(scenario, 2, P1_addy);
        make_player_move_for_tests(scenario, 3, P2_addy);
        make_player_move_for_tests(scenario, 2, P1_addy);
        make_player_move_for_tests(scenario, 3, P2_addy);
        make_player_move_for_tests(scenario, 3, P1_addy);
        make_player_move_for_tests(scenario, 5, P2_addy);
        make_player_move_for_tests(scenario, 3, P1_addy);

        scenario.next_tx(P1_addy);
        {
            let mut game_val = scenario.take_shared<GameBoard>();
            let game = &mut game_val;
            print_board(game);
            // Check for a win
            let has_won = check_for_win_in_tests(game, 1);
            assert!(has_won, 1);
            test_scenario::return_shared(game_val);
        };
        scenario_val.end();
    }

    fun make_player_move_for_tests(scenario: &mut Scenario, column: u64, player_addy: address) {
        scenario.next_tx(player_addy);
        {
            let mut game_val = scenario.take_shared<GameBoard>();
            let game = &mut game_val;
            player_move(game, column, scenario.ctx());
            test_scenario::return_shared(game_val);
        };
    }


}