module find_four::profile_and_rank {

    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{String};
    use 0x1::u64::{max, divide_and_round_up};
    use find_four::FFIO::{ FindFourAdminCap};

    const VERSION: u64 = 1;

    // Profile structure
    public struct Profile has store, copy, drop {
        image_url: String,
        username: String,
        trophies: u64,
    }

    // Shared object to hold all profiles
    public struct ProfileTable has key {
        id: UID,
        profiles: Table<address, Profile>,
        version: u64
    }

    // Function to initialize the module by creating the shared ProfileTable
    fun init(ctx: &mut TxContext) {
        transfer::share_object(ProfileTable {
            id: object::new(ctx),
            profiles: table::new<address, Profile>(ctx),
            version: VERSION
        });
    }

    // Function to add or update a profile
    public entry fun add_or_update_profile(
        table: &mut ProfileTable,
        image_url: String,
        username: String,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let profile = Profile { 
            image_url: image_url, 
            username: username, 
            trophies: 50 };
        if (table::contains(&table.profiles, sender)) {
            let myProfile = table::borrow_mut(&mut table.profiles, sender);
            myProfile.image_url = image_url;
            myProfile.username = username;
        } else {
            table::add(&mut table.profiles, sender, profile);
        }
    }

    // Function to view a profile
    public(package) fun view_profile(table: &ProfileTable, owner: address): &Profile {
        assert!(table::contains(&table.profiles, owner), 0);
        table::borrow(&table.profiles, owner)
    }

    // Function to remove a profile (only callable by the profile owner)
    // public entry fun remove_profile(table: &mut ProfileTable, ctx: &mut TxContext) {
    //     let sender = tx_context::sender(ctx);
    //     assert!(table::contains(&table.profiles, sender), 0);
    //     table::remove(&mut table.profiles, sender);
    // }

    // Function to update trophies (adding to the existing count)
    public(package) entry fun update_trophies(
        table: &mut ProfileTable,
        trophies_to_add_or_sub: u64,
        add: bool,
        addy: address,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&table.profiles, addy), 0);
        let profile = table::borrow_mut(&mut table.profiles, addy);
        if(add){
            profile.trophies = profile.trophies + trophies_to_add_or_sub;
        }else{
            profile.trophies = subtract_not_under_zero(profile.trophies, trophies_to_add_or_sub)
        }
    }

    public entry fun update_version(_: &FindFourAdminCap, profileTable: &mut ProfileTable) {
        profileTable.version = VERSION;
    }

    fun check_version_ProfileTable(profileTable: &ProfileTable){
        assert!(profileTable.version == VERSION, 1);
    }


//     use std::string::{String};
//     use sui::table::{Table};
//     // use find_four::find_four_game::{ GameBoard};
//     // use sui::random::{Self, Random, RandomGenerator, create_for_testing};
//     use 0x1::u64::{max, divide_and_round_up};
//     // use find_four::FFIO::{create_reward_account, RewardAccount};

    //   const VERSION: u64 = 1;

//     const DummyObjAddy: address = @0xFFFFF;

//     public struct Profile has key, store {
//         id: UID,
//         username: String,
//         profilePicAddy: address,
//         pointsObj: address,
//         version: u64,
//         currentGame: address,
//         owner: address,
//         // rewardAccount: RewardAccount
//     }

//     public struct PointsObj has key, store {
//         id: UID,
//         points: u64
//     }

//     public struct PointValToNumOfPlayersList has key, store {
//         id: UID,
//         list: Table<u64, u64>
//     }

//     fun init(ctx: &mut TxContext){
//         let list = initialize_list( ctx);
//         transfer::share_object(list);
//     }

//     // Initializes the waiting list
//     fun initialize_list(ctx: &mut TxContext): PointValToNumOfPlayersList {
//         PointValToNumOfPlayersList {
//             id: object::new(ctx),
//             list: sui::table::new(ctx),
//         }
//     }


// //     public entry fun init(ctx: &mut TxContext) {
// //         let table: Table<u64, u64> = table::new(ctx);
        
// //         // For demonstration, add an entry
// //         table::add(&mut table, 1, 100);

// //         // If you want to create an object that contains the table
// //         let my_table = MyTable<u64, u64> {
// //             id: object::new(ctx),
// //             table_values: table
// //         };
        
// //         // Share the object or transfer it
// //         transfer::share_object(my_table);
// //     }
// // }

//     public(package) fun getPointsObj(profile: &mut Profile): address {
//         profile.pointsObj
//     }

//     // public(package) fun getRewardAccount(profile: &mut Profile): &mut RewardAccount {
//     //     &mut profile.rewardAccount
//     // }

//     public fun create_profile(username: String, profilePicAddy: address, ctx: &mut TxContext) {
//         let uid = object::new(ctx);
//         let pointsObjAddy = object::uid_to_address(&uid);
//         let myPointsObj = PointsObj {
//             id: uid,
//             points: 50
//         };
//         transfer::share_object(myPointsObj);
//         // let reward_account = create_reward_account(ctx);
//         let profile = Profile {
//             id: object::new(ctx),
//             username: username,
//             profilePicAddy: profilePicAddy,
//             pointsObj: pointsObjAddy,
//             version: 1,
//             currentGame: DummyObjAddy,
//             owner: ctx.sender(),
//             // rewardAccount: reward_account
//         };
//         transfer::public_transfer(profile, ctx.sender());
//     }

//     public fun edit_profile(profile: &mut Profile, username: String, profilePicAddy: address, ctx: &mut TxContext) {
//         assert!(profile.owner == ctx.sender(), 1);
//         profile.username = username;
//         profile.profilePicAddy = profilePicAddy;
//     }

//     // public fun generate_random_range(random_obj: &Random, min: u64, max: u64, ctx: &mut TxContext): u64 {
//     //     let generator = random::new_generator(random_obj, ctx);
//     //     random::generate_u64_in_range(&mut generator, min, max)
//     // }

    public fun subtract_not_under_zero(left: u64, right: u64): u64{
        if(left >= right){
            return (left - right);
        };
        return 0
    }

    public(package) fun update_both_trophies_after_win(table: &mut ProfileTable, winner: u64, p1: address, p2: address, ctx: &mut TxContext) {
        check_version_ProfileTable(table);
        // if (isGameOver(game) && !winningHandled(game)){
        // let po1 = pointsObj1.points;
        // let po2 = pointsObj2.points;
        // TODO randomize a bit
        // let rand = generate_random_range(create_for_testing(ctx), min, max, ctx)
        let points1 = view_profile(table, p1).trophies;
        let points2 = view_profile(table, p2).trophies;
        assert!(winner != 0, 1);
        // TODO - handle points logic and changing
        if (winner == 1){
            let mut change: u64 = 5;
            if (points1 < points2){
                change = max(divide_and_round_up((points2 - points1), 2), 25);
            };
            update_trophies(table, change, true, p1, ctx);
            update_trophies(table, change, false, p2, ctx);
                //expected
                // pointsObj1.points1 = pointsObj1.points + 5; //better player won, small reward
                // pointsObj2.points = subtract_not_under_zero(pointsObj2.points, 5); //worse player lost, small loss
                // update_trophies(table, 5, true, p1, ctx);
                // update_trophies(table, 5, false, p2, ctx);
            // }else{
                //not expected
                // let difference = ;
                // let change = max(divide_and_round_up((points2 - points1), 2), 25);
                // update_trophies(table, (change), true, p1, ctx);
                // update_trophies(table, change, false, p2, ctx);

                // let difference = subtract_not_under_zero(pointsObj1.points, pointsObj2.points);
                // let movement = max(divide_and_round_up(difference, 2), 25);
                // pointsObj1.points = subtract_not_under_zero(pointsObj1.points, movement); //better player lost, big loss
                // pointsObj2.points = pointsObj2.points + movement; //worse player won, big reward
            // }
        }else{
            let mut change = 5;
            if (points2 < points1){
                change = max(divide_and_round_up((points1 - points2), 2), 25);
            };
            update_trophies(table, change, true, p2, ctx);
            update_trophies(table, change, false, p1, ctx);
            // if (pointsObj2.points >= pointsObj1.points){
            //     //expected
            //     pointsObj2.points = pointsObj2.points + 5; //better player won, small reward
            //     pointsObj1.points = subtract_not_under_zero(pointsObj1.points, 5); //worse player lost, small loss
            // }else{
            //     //not expected
            //     let difference = subtract_not_under_zero(pointsObj2.points, pointsObj1.points);
            //     let movement = max(divide_and_round_up(difference, 2), 25);
            //     pointsObj2.points = subtract_not_under_zero(pointsObj2.points, movement); //better player lost, big loss
            //     pointsObj1.points = pointsObj1.points + movement; //worse player won, big reward
            // }
        }
    }
    // }
}