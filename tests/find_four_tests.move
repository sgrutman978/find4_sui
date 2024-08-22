
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
module find_four::my_module_tests {
    use sui::test_scenario::{Self};//, Scenario};
    // use find_four::game::{GameBoard};

   #[test]
fun test_game() {
    // Create test addresses representing users
    let p1 = @0xCAFE;
    // let p2 = @0xFACE;

    let mut scenario_val = test_scenario::begin(p1);
    let scenario = &mut scenario_val;
    let game = find_four::find_four_game::initialize_game(scenario.ctx());
    transfer::public_transfer(game, @0xDEAD);
    scenario_val.end();
}


}