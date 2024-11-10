module find_four::profile_and_rank {

    use std::string::{String};
    use sui::table::{Table};
    use find_four::find_four_game::{ GameBoard, isGameOver, winningHandled, handleWinning};

    const DummyObjAddy: address = @0xFFFFF;

    public struct Profile has key, store {
        id: UID,
        username: String,
        profilePicUrl: String,
        pointsObj: address,
        version: u64,
        currentGame: address
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

    public fun create_profile(username: String, profilePicUrl: String, ctx: &mut TxContext): Profile {
        let uid = object::new(ctx);
        let pointsObjAddy = object::uid_to_address(&uid);
        let myPointsObj = PointsObj {
            id: uid,
            points: 50
        };
        transfer::share_object(myPointsObj);
        let profile = Profile {
            id: object::new(ctx),
            username: username,
            profilePicUrl: profilePicUrl,
            pointsObj: pointsObjAddy,
            version: 1,
            currentGame: DummyObjAddy
        };
        profile
    }

    public(package) fun updatePoints(game: &mut GameBoard, pointsObj1: &mut PointsObj, pointsObj2: &mut PointsObj) {
        if (isGameOver(game) && !winningHandled(game)){
            // TODO - handle points logic and changing
            handleWinning(game);
        }
    }
}