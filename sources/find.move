module find_four::FFIO {

    use sui::vec_map::{Self, VecMap};
    use sui::math;
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::url::Url;
    use std::debug;
    use sui::table::{Self, Table};

    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID};
    use std::vector;

 

    const VERSION: u64 = 1;
    const EInsufficientBalance: u64 = 0;
        const OneCoinNineDecimals: u64 = 1000000000;

    /* ========== OBJECTS ========== */

    public struct Treasury has key {
        id: UID,
        rewardsTreasury: Balance<FFIO>, // Staking rewards held in the treasury
        stakedCoinsTreasury: Balance<FFIO>, // Staked Sui coins held in the treasury
        gameRewardsTreasury: Balance<FFIO>,
        version: u64
    }

        // Struct to hold staking information
    public struct StakeObject has key {
        id: UID,
        // owner: address,
        amount: u64,
        start_epoch: u64,
        reward_rate: u64
    }

    // Struct to manage staking pool
    public struct StakingPool has key {
        id: UID,
        total_staked: Balance<FFIO>, //NOT USED FOR ANYTHING EVER
        reward_rate: u64, // Rewards per second per token staked
        last_updated_time: u64,
        version: u64
    }

    public struct FFIO has drop {}

    public struct FindFourAdminCap has key { id: UID }


    fun init (witness: FFIO, ctx: &mut TxContext){
        transfer::transfer(FindFourAdminCap {
            id: object::new(ctx)
        }, ctx.sender());
        transfer::transfer(FindFourAdminCap {id: object::new(ctx)}, tx_context::sender(ctx));
        let (mut treasury, metadata) = coin::create_currency(witness, 9, b"WJKL4", b"F", b"Play to earn!", option::some(create_url(b"https://www.find4.io/f4-42.png")), ctx);
        let half_bil = 500000000*OneCoinNineDecimals;
        let staking_rewards_coins = coin::mint<FFIO>(&mut treasury, 8*half_bil, ctx);
        let game_rewards_coins = coin::mint<FFIO>(&mut treasury, 10*half_bil, ctx);
        let presale_coins = coin::mint<FFIO>(&mut treasury, 4*half_bil, ctx);
        let mut treasury_obj = Treasury{
            id: object::new(ctx),
            rewardsTreasury: balance::zero<FFIO>(),
            stakedCoinsTreasury: balance::zero<FFIO>(),
            gameRewardsTreasury: balance::zero<FFIO>(),
            version: VERSION};
        let balance1 = coin::into_balance(staking_rewards_coins);
        balance::join(&mut treasury_obj.rewardsTreasury, balance1);
        let balance2 = coin::into_balance(game_rewards_coins);
        balance::join(&mut treasury_obj.gameRewardsTreasury, balance2);
        transfer::share_object(treasury_obj);
        let team_coins = coin::mint<FFIO>(&mut treasury, 14*half_bil, ctx);
        transfer::public_transfer(team_coins, ctx.sender());
        //TODO add other groups of coins
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender());
        let balance3 = coin::into_balance(presale_coins);
        let presale_state = PresaleState {
            id: object::new(ctx),
            token_supply: balance3,
            price: OneCoinNineDecimals/100, // 0.01 SUI per token if SUI has 9 decimals
            tokens_sold: 0,
            cap: 4*half_bil, // Example cap of 1,000 tokens if TOKEN has 9 decimals
            version: VERSION
        };
        transfer::share_object(presale_state);
    }

    //check versions of shared treasury object
    fun check_version_Treasury(treasury: &Treasury){
        assert!(treasury.version == VERSION, 1);
    }

    //check versions of shared presale object
    fun check_version_PresaleState(presaleState: &PresaleState){
        assert!(presaleState.version == VERSION, 1);
    }

    fun check_version_StakingPool(staking_pool: &StakingPool){
        assert!(staking_pool.version == VERSION, 1);
    }

    /// Automatically adds a reward when a player wins a game, drawing from the reward pool
    public(package) fun reward_winner(
        treasury: &mut Treasury,
        amount: u64,
        ctx: &mut TxContext
    ) {
        check_version_Treasury(treasury);
        let withdrawalAmount = coin::take<FFIO>(&mut treasury.gameRewardsTreasury, amount, ctx);
        transfer::public_transfer(withdrawalAmount, ctx.sender());
    }


    /* ========== USER FUNCTIONS ========== */

//////////////////////////// Presale ///////////////////////////////

    // Define the presale state
    public struct PresaleState has key {
        id: UID,
        token_supply: Balance<FFIO>,
        price: u64, // Price in SUI per token
        tokens_sold: u64,
        cap: u64,  // Maximum number of tokens for sale
        version: u64
    }

    // Function to buy tokens during presale
    public entry fun buy_token(presale: &mut PresaleState, mut payment: Coin<SUI>, amount: u64, ctx: &mut TxContext) {
        check_version_PresaleState(presale);
        let total_cost = amount * presale.price;
        let ffio_tokens_to_buy = amount*OneCoinNineDecimals;
        assert!(coin::value(&payment) >= total_cost, 0); // Ensure enough payment
        assert!(presale.tokens_sold + ffio_tokens_to_buy <= presale.cap, 1); // Ensure we don't exceed cap
        let tokens = coin::take<FFIO>(&mut presale.token_supply, ffio_tokens_to_buy, ctx);
        // Update sold tokens count
        presale.tokens_sold = presale.tokens_sold + ffio_tokens_to_buy;
        // Split the payment coin into cost and remainder
        let cost = coin::split(&mut payment, total_cost, ctx);
        // Transfer cost to the presale organizer's address
        transfer::public_transfer(cost, @0x8418bb05799666b73c4645aa15e4d1ccae824e1487c01a665f51767826d192b7); // Replace with the address where you want SUI to go
        // Return any remainder to the buyer
        transfer::public_transfer(payment, tx_context::sender(ctx));
        // Transfer tokens to buyer
        transfer::public_transfer(tokens, ctx.sender());
    }

    public entry fun updatePresalePrice(_: &FindFourAdminCap, presale: &mut PresaleState, newPrice: u64, ctx: &mut TxContext) {
        presale.price = newPrice;
    }

    public entry fun updateCap(_: &FindFourAdminCap, presale: &mut PresaleState, cap: u64, ctx: &mut TxContext) {
        presale.cap = cap;
    }

    // Function to end presale and return remaining tokens to owner
    // public entry fun end_presale(presale: &mut PresaleState, ctx: &mut TxContext) {
    //     let PresaleState { id, total_supply, price: _, tokens_sold: _, cap: _ } = presale;
    //     object::delete(id);
    //     let remaining = coin::mint(&mut total_supply, balance::supply_value(&total_supply), ctx);
    //     transfer::transfer(remaining, tx_context::sender(ctx));
    // }
// }

    public entry fun distribute_tokens4(
        mut coin: Coin<FFIO>,
        addresses: vector<address>,
        amount_per_address: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        // Check if there are enough funds to distribute
        let total_to_distribute = (amount_per_address as u64) * (vector::length(&addresses) as u64);
        assert!(coin::value(&coin) >= total_to_distribute, EInsufficientBalance);

        // Iterate over the list of addresses
        let mut i = 0;
        let length = vector::length(&addresses);
        while (i < length) {
            let address = *vector::borrow(&addresses, i);
            // Transfer the fixed amount to each address
            transfer::public_transfer(coin::split(&mut coin, amount_per_address, ctx), address);
            i = i + 1;
        };
        transfer::public_transfer(coin, ctx.sender());
    }

    public entry fun migrate(_: &FindFourAdminCap, ctx: &mut TxContext){
        let staking_pool = StakingPool {
            id: object::new(ctx),
            total_staked: balance::zero(),
            reward_rate: 10,
            last_updated_time: 0,
            version: VERSION
        };
        transfer::share_object(staking_pool);
    }

    public entry fun stake_existing_ffio(staking_pool: &mut StakingPool, coin: Coin<FFIO>, treasury: &mut Treasury, clock: &Clock, stake_object: StakeObject, ctx: &mut TxContext){
        check_version_StakingPool(staking_pool);
        claim_rewards(staking_pool, treasury, &stake_object, clock, ctx);
        assert!(ctx.sender() != @0xCAFE, 1);
        let amount = coin::value(&coin) + stake_object.amount;

        // let balance = coin::into_balance(coin);
        // balance::join(&mut treasury.stakedCoinsTreasury, balance);
        let new_stake_object = StakeObject {
            id: object::new(ctx),
            // staker,
            amount: amount,
            start_epoch: getCurrentEpoch(clock), 
            reward_rate: staking_pool.reward_rate
        };
        let balance = coin::into_balance(coin);
        balance::join(&mut treasury.stakedCoinsTreasury, balance);
        transfer::transfer(new_stake_object, ctx.sender());
        transfer::transfer(stake_object, @0xCAFE);
    }

    // Stake function
    public entry fun stake_new_ffio(staking_pool: &mut StakingPool, coin: Coin<FFIO>, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        check_version_StakingPool(staking_pool);
        assert!(ctx.sender() != @0xCAFE, 1);
        let stake_object = StakeObject {
            id: object::new(ctx),
            // staker,
            amount: coin::value(&coin),
            start_epoch: getCurrentEpoch(clock), 
            reward_rate: staking_pool.reward_rate
        };
        let balance = coin::into_balance(coin);
        balance::join(&mut treasury.stakedCoinsTreasury, balance);
        transfer::transfer(stake_object, ctx.sender());
    }

    // Function to unstake
    public entry fun unstake_ffio(staking_pool: &mut StakingPool, treasury: &mut Treasury, stake_object: &mut StakeObject, clock: &Clock, ctx: &mut TxContext) {
        assert!(ctx.sender() != @0xCAFE, 1);
        check_version_StakingPool(staking_pool);
        claim_rewards(staking_pool, treasury, stake_object, clock, ctx);
        let unstake_coin = coin::take<FFIO>(&mut treasury.stakedCoinsTreasury, stake_object.amount, ctx);
        transfer::public_transfer(unstake_coin, sender(ctx));
        stake_object.amount = 0;
    }

    fun getCurrentEpoch(clock: &Clock): u64{
        (clock::timestamp_ms(clock) / 1000) // Converts to seconds
    }

    public(package) fun getStakedAmount(stakedObj: &StakeObject): u64{
        stakedObj.amount
    }

    // Calculate rewards for a stake
    public fun calculate_rewards(staking_pool: &StakingPool, stake_object: &StakeObject, clock: &Clock): u64 {
        check_version_StakingPool(staking_pool);
        if (staking_pool.reward_rate >= stake_object.reward_rate) {
            return staking_pool.reward_rate * (getCurrentEpoch(clock) - stake_object.start_epoch) * (stake_object.amount / OneCoinNineDecimals);
        }else{
            return stake_object.reward_rate * (getCurrentEpoch(clock) - stake_object.start_epoch) * (stake_object.amount / OneCoinNineDecimals);
        };
        0
    }

    // Claim rewards
    public fun claim_rewards(staking_pool: &mut StakingPool, treasury: &mut Treasury, stake_object: &StakeObject, clock: &Clock, ctx: &mut TxContext) {
        assert!(ctx.sender() != @0xCAFE, 1);
        check_version_StakingPool(staking_pool);
        let reward_amount = calculate_rewards(staking_pool, stake_object, clock);
        let reward_coin = coin::take<FFIO>(&mut treasury.rewardsTreasury, reward_amount, ctx);
        transfer::public_transfer(reward_coin, sender(ctx));
    }

    // Claim rewards
    public fun claim_rewards2(staking_pool: &mut StakingPool, treasury: &mut Treasury, stake_object: StakeObject, clock: &Clock, ctx: &mut TxContext) {
        assert!(ctx.sender() != @0xCAFE, 1);
        check_version_StakingPool(staking_pool);
        let reward_amount = calculate_rewards(staking_pool, &stake_object, clock);
        let reward_coin = coin::take<FFIO>(&mut treasury.rewardsTreasury, reward_amount, ctx);
        transfer::public_transfer(reward_coin, sender(ctx));

        let new_stake_object = StakeObject {
            id: object::new(ctx),
            // staker,
            amount: stake_object.amount,
            start_epoch: getCurrentEpoch(clock), 
            reward_rate: staking_pool.reward_rate
        };
        transfer::transfer(new_stake_object, ctx.sender());
        transfer::transfer(stake_object, @0xCAFE);
        // stake_object.start_epoch = getCurrentEpoch(clock);
    }

    public fun update_reward_rate(_: &FindFourAdminCap, staking_pool: &mut StakingPool, rate: u64, clock: &Clock) {
        check_version_StakingPool(staking_pool);
        staking_pool.reward_rate = rate;
        staking_pool.last_updated_time = getCurrentEpoch(clock);
    }

    public entry fun update_version3(_: &FindFourAdminCap, staking_pool: &mut StakingPool, treasury: &mut Treasury, presaleState: &mut PresaleState) {
        staking_pool.version = VERSION;
        treasury.version = VERSION;
        presaleState.version = VERSION;
    }

























































































































































































/////////////////////////////// DEPRECATED //////////////////////////////////////



// public fun claim_rewards(staking_pool: &mut StakingPool, treasury: &mut Treasury, stake_object: &StakeObject, clock: &Clock, ctx: &mut TxContext) {}
    public struct RewardState has key {
        id: UID,
        duration: u64, // Set by the Owner: Duration of rewards to be paid out (in seconds)
        finishAt: u64, // Timestamp of when the rewards finish
        updatedAt: u64, // Minimum of last updated time and reward finish time
        rewardRate: u64, // Reward to be paid out per second: determined by the duration & amount of rewards
        version: u64
    }
        public struct UserState2 has key {
        id: UID,
        rewardPerTokenStored: u64, // Sum of (reward rate * dt * 1^(token_decimal) / total staked supply) where dt is the time difference between current time and last updated time
        userRewardPerTokenPaid: Table<address, u64>, // Mapping that keeps track of users' rewardPerTokenStored
        balanceOf: Table<address, u64>, // Mapping that keeps track of users' staked amount 
        rewards: Table<address, u64>, // Mapping that keeps track of users' rewards to be claimed
        version: u64
    }
    public entry fun distribute_tokens2(coin: &mut Coin<FFIO>, addresses: vector<address>, amount_per_address: u64, ctx: &mut TxContext) {
        debug::print(&b"Deprecated!");
    }
    public entry fun distribute_tokens3(coin: &mut Coin<FFIO>, addresses: vector<address>, amount_per_address: u64, ctx: &mut TxContext) {
        debug::print(&b"Deprecated!");
    }
    public struct UserState has key {
        id: UID,
        rewardPerTokenStored: u64, // Sum of (reward rate * dt * 1^(token_decimal) / total staked supply) where dt is the time difference between current time and last updated time
        userRewardPerTokenPaid: VecMap<address, u64>, // Mapping that keeps track of users' rewardPerTokenStored
        balanceOf: VecMap<address, u64>, // Mapping that keeps track of users' staked amount 
        rewards: VecMap<address, u64>, // Mapping that keeps track of users' rewards to be claimed
        version: u64
    }
    fun check_version_UserState(userState: &UserState){
        debug::print(&b"old version");
    }
    public entry fun stake (payment: Coin<FFIO>, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        check_version_UserState(userState);
        let balance = coin::into_balance(payment);
        balance::join(&mut treasury.stakedCoinsTreasury, balance);
        debug::print(&b"old version");
    }
    public entry fun withdraw(userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        debug::print(&b"old version");
    }
    public entry fun getReward(userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        debug::print(&b"old version");
    }
    public entry fun update_version(_: &FindFourAdminCap, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, presaleState: &mut PresaleState) {
        debug::print(&b"old version");
    }
    public entry fun setRewardAmount(_: &FindFourAdminCap, reward: Coin<FFIO>, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock) {
        check_version_UserState(userState);
        let amount = coin::value(&reward);
        let balance = coin::into_balance(reward);
        balance::join(&mut treasury.rewardsTreasury, balance);
        debug::print(&b"old version");
    }
    fun updateReward(totalStakedSupply: u64, account: address, userState: &mut UserState, rewardState: &mut  RewardState, clock :&Clock){
        debug::print(&b"old version");
    }
    fun earned(totalStakedSupply: u64, account: address, userState: &UserState, rewardState: &RewardState, clock: &Clock): u64{
        return (0 as u64)
    }
    fun rewardPerToken(totalStakedSupply: u64, userState: &UserState2, rewardState: &RewardState, clock: &Clock): u64 {
        return (0 as u64)
    }
        public struct RewardAdded has copy, drop{
        reward: u64
    }

    public struct RewardDurationUpdated has copy, drop {
         newDuration: u64
    }

    public struct Staked has copy, drop{
        user: address,
        amount: u64
    }

    public struct Withdrawn has copy, drop {
        user: address,
        amount: u64
    }

    public struct RewardPaid has copy, drop {
        user: address,
        reward: u64
    }

    public(package) fun create_url(url: vector<u8>): Url {
        let url = sui::url::new_unsafe(std::ascii::string(url));
        url
    }

    fun check_version_RewardState(rewardState: &RewardState){
        assert!(rewardState.version == VERSION, 1);
    }
    fun check_version_UserState2(userState: &UserState2){
        assert!(userState.version == VERSION, 1);
    }
    /* ========== ERRORS ========== */

    const ERewardDurationNotExpired: u64 = 100;
    const EZeroRewardRate: u64 = 101;
    const EZeroAmount: u64 = 102;
    const ELowRewardsTreasuryBalance: u64 = 103;
    const ERequestedAmountExceedsStaked: u64 = 104;
    const ENoRewardsToClaim: u64 = 105;
    const ENoStakedTokens: u64 = 106;
    const ENoPriorTokenStake: u64 = 107;
    const REWARD_ALREADY_CLAIMED: u64 = 108; 
    const INSUFFICIENT_POOL_BALANCE: u64 = 109; 

    public entry fun stake2 (payment: Coin<FFIO>, userState: &mut UserState2, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        assert!(0 == 1, 1);
        let balance = coin::into_balance(payment);
        balance::join(&mut treasury.stakedCoinsTreasury, balance);
        debug::print(&b"old version");
    }
    public entry fun withdraw2(userState: &mut UserState2, rewardState: &mut RewardState, treasury: &mut Treasury, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        debug::print(&b"old version");
    }
    public entry fun getReward2(userState: &mut UserState2, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
       debug::print(&b"old version");
    }
    public entry fun setRewardDuration(_: &FindFourAdminCap, rewardState: &mut RewardState, duration: u64, clock: &Clock) {
        debug::print(&b"old version");
    }
    public entry fun setRewardAmount2(_: &FindFourAdminCap, reward: Coin<FFIO>, userState: &mut UserState2, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock) {
        assert!(0 == 1, 1);
        let balance = coin::into_balance(reward);
        balance::join(&mut treasury.rewardsTreasury, balance);
        debug::print(&b"old version");
    }
    fun updateReward2(totalStakedSupply: u64, account: address, userState: &mut UserState2, rewardState: &mut  RewardState, clock :&Clock){
        debug::print(&b"old version");
    }
    fun earned2(totalStakedSupply: u64, account: address, userState: &UserState2, rewardState: &RewardState, clock: &Clock): u64{
        debug::print(&b"old version");
        0
    }
    fun rewardPerToken2(totalStakedSupply: u64, userState: &UserState2, rewardState: &RewardState, clock: &Clock): u64 {
        debug::print(&b"old version");
        0
    }
    public entry fun update_version2(_: &FindFourAdminCap, userState: &mut UserState2, rewardState: &mut RewardState, treasury: &mut Treasury, presaleState: &mut PresaleState) {
        debug::print(&b"old version");
    }
    public entry fun distribute_tokens<T>(coin: &mut Coin<T>, addresses: vector<address>, amount_per_address: u64, ctx: &mut TxContext) { }
       
        // fun init (witness: FFIO, ctx: &mut TxContext){
        // transfer::transfer(FindFourAdminCap {
        //     id: object::new(ctx)
        // }, ctx.sender());
        // transfer::share_object(RewardState{
        //     id: object::new(ctx),
        //     duration: 0,
        //     finishAt: 0,
        //     updatedAt: 0,
        //     rewardRate: 0,
        //     version: VERSION
        // });
        // transfer::share_object(UserState2{
        //     id: object::new(ctx),
        //     rewardPerTokenStored: 0,
        //     userRewardPerTokenPaid: table::new<address, u64>(ctx),
        //     balanceOf: table::new<address, u64>(ctx),
        //     rewards: table::new<address, u64>(ctx),
        //     version: VERSION
        // });

}
