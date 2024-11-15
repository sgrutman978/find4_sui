module find_four::profile_and_rank {

    use std::string::{String};
    use sui::table::{Table};
    // use find_four::find_four_game::{ GameBoard};
    // use sui::random::{Self, Random, RandomGenerator, create_for_testing};
    use 0x1::u64::{max, divide_and_round_up};
    use find_four::FFIO::{create_reward_account, RewardAccount};

    const DummyObjAddy: address = @0xFFFFF;

    public struct Profile has key, store {
        id: UID,
        username: String,
        profilePicAddy: address,
        pointsObj: address,
        version: u64,
        currentGame: address,
        owner: address,
        rewardAccount: RewardAccount
    }

    public struct PointsObj has key, store {
        id: UID,
        points: u64
    }

    public struct PointValToNumOfPlayersList has key, store {
        id: UID,
        list: Table<u64, u64>
    }

    fun init(ctx: &mut TxContext){
        let list = initialize_list( ctx);
        transfer::share_object(list);
    }

    // Initializes the waiting list
    fun initialize_list(ctx: &mut TxContext): PointValToNumOfPlayersList {
        PointValToNumOfPlayersList {
            id: object::new(ctx),
            list: sui::table::new(ctx),
        }
    }


//     public entry fun init(ctx: &mut TxContext) {
//         let table: Table<u64, u64> = table::new(ctx);
        
//         // For demonstration, add an entry
//         table::add(&mut table, 1, 100);

//         // If you want to create an object that contains the table
//         let my_table = MyTable<u64, u64> {
//             id: object::new(ctx),
//             table_values: table
//         };
        
//         // Share the object or transfer it
//         transfer::share_object(my_table);
//     }
// }

    public(package) fun getPointsObj(profile: &mut Profile): address {
        profile.pointsObj
    }

    public(package) fun getRewardAccount(profile: &mut Profile): &mut RewardAccount {
        &mut profile.rewardAccount
    }

    public fun create_profile(username: String, profilePicAddy: address, ctx: &mut TxContext) {
        let uid = object::new(ctx);
        let pointsObjAddy = object::uid_to_address(&uid);
        let myPointsObj = PointsObj {
            id: uid,
            points: 50
        };
        transfer::share_object(myPointsObj);
        let reward_account = create_reward_account(ctx);
        let profile = Profile {
            id: object::new(ctx),
            username: username,
            profilePicAddy: profilePicAddy,
            pointsObj: pointsObjAddy,
            version: 1,
            currentGame: DummyObjAddy,
            owner: ctx.sender(),
            rewardAccount: reward_account
        };
        transfer::public_transfer(profile, ctx.sender());
    }

    public fun edit_profile(profile: &mut Profile, username: String, profilePicAddy: address, ctx: &mut TxContext) {
        assert!(profile.owner == ctx.sender(), 1);
        profile.username = username;
        profile.profilePicAddy = profilePicAddy;
    }

    // public fun generate_random_range(random_obj: &Random, min: u64, max: u64, ctx: &mut TxContext): u64 {
    //     let generator = random::new_generator(random_obj, ctx);
    //     random::generate_u64_in_range(&mut generator, min, max)
    // }

    public fun subtract_not_under_zero(left: u64, right: u64): u64{
        if(left >= right){
            return (left - right);
        };
        return 0
    }

    public(package) fun updatePoints(winner: u64, pointsObj1: &mut PointsObj, pointsObj2: &mut PointsObj, ctx: &mut TxContext) {
        // if (isGameOver(game) && !winningHandled(game)){
        let po1 = copy pointsObj1.points;
        let po2 = copy pointsObj2.points;
        // TODO randomize a bit
        // let rand = generate_random_range(create_for_testing(ctx), min, max, ctx)
        assert!(winner != 0, 1);
        // TODO - handle points logic and changing
        if (winner == 1){
            if (po1 >= po2){
                //expected
                pointsObj1.points = po1 + 5; //better player won, small reward
                pointsObj2.points = subtract_not_under_zero(po2, 5); //worse player lost, small loss
            }else{
                //not expected
                let difference = subtract_not_under_zero(po1, po2);
                let movement = max(divide_and_round_up(difference, 2), 25);
                pointsObj1.points = subtract_not_under_zero(po1, movement); //better player lost, big loss
                pointsObj2.points = po2 + movement; //worse player won, big reward
            }
        }else{
            if (po2 >= po1){
                //expected
                pointsObj2.points = po1 + 5; //better player won, small reward
                pointsObj1.points = subtract_not_under_zero(po1, 5); //worse player lost, small loss
            }else{
                //not expected
                let difference = subtract_not_under_zero(po2, po1);
                let movement = max(divide_and_round_up(difference, 2), 25);
                pointsObj2.points = subtract_not_under_zero(po2, movement); //better player lost, big loss
                pointsObj1.points = po1 + movement; //worse player won, big reward
            }
        }
    }
    // }
}