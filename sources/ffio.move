module find_four::FFIO {

    use sui::vec_map::{Self, VecMap};
    use sui::math;
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::url::Url;

    public struct FFIO has drop {}

    const VERSION: u64 = 1;

    /* ========== OBJECTS ========== */

    public struct RewardState has key {
        id: UID,
        duration: u64, // Set by the Owner: Duration of rewards to be paid out (in seconds)
        finishAt: u64, // Timestamp of when the rewards finish
        updatedAt: u64, // Minimum of last updated time and reward finish time
        rewardRate: u64, // Reward to be paid out per second: determined by the duration & amount of rewards
        version: u64
    }

    public struct UserState has key {
        id: UID,
        rewardPerTokenStored: u64, // Sum of (reward rate * dt * 1^(token_decimal) / total staked supply) where dt is the time difference between current time and last updated time
        userRewardPerTokenPaid: VecMap<address, u64>, // Mapping that keeps track of users' rewardPerTokenStored
        balanceOf: VecMap<address, u64>, // Mapping that keeps track of users' staked amount 
        rewards: VecMap<address, u64>, // Mapping that keeps track of users' rewards to be claimed
        version: u64
    }

    public struct Treasury has key {
        id: UID,
        rewardsTreasury: Balance<FFIO>, // Staking rewards held in the treasury
        stakedCoinsTreasury: Balance<FFIO>, // Staked Sui coins held in the treasury
        gameRewardsTreasury: Balance<FFIO>,
        version: u64
    }

    public struct FindFourAdminCap has key { id: UID }

    /* ========== EVENTS ========== */

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

    /* ========== ERRORS ========== */

    const ERewardDurationNotExpired: u64 = 100;
    const EZeroRewardRate: u64 = 101;
    const EZeroAmount: u64 = 102;
    const ELowRewardsTreasuryBalance: u64 = 103;
    const ERequestedAmountExceedsStaked: u64 = 104;
    const ENoRewardsToClaim: u64 = 105;
    const ENoStakedTokens: u64 = 106;
    const ENoPriorTokenStake: u64 = 107;
    // const REWARD_ALREADY_CLAIMED: u64 = 108; 
    // const INSUFFICIENT_POOL_BALANCE: u64 = 109; 

    const OneCoinNineDecimals: u64 = 1000000000;


    /* ========== CONSTRUCTOR ========== */

    fun init (witness: FFIO, ctx: &mut TxContext){
        transfer::transfer(FindFourAdminCap {
            id: object::new(ctx)
        }, ctx.sender());
        transfer::share_object(RewardState{
            id: object::new(ctx),
            duration: 0,
            finishAt: 0,
            updatedAt: 0,
            rewardRate: 0,
            version: VERSION
        });
        transfer::share_object(UserState{
            id: object::new(ctx),
            rewardPerTokenStored: 0,
            userRewardPerTokenPaid: vec_map::empty<address, u64>(),
            balanceOf: vec_map::empty<address, u64>(),
            rewards: vec_map::empty<address, u64>(),
            version: VERSION
        });
        transfer::transfer(FindFourAdminCap {id: object::new(ctx)}, tx_context::sender(ctx));

        let (mut treasury, metadata) = coin::create_currency(witness, 9, b"FFIO", b"Find4.io Coin", b"Play to earn!", option::some(create_url(b"https://www.find4.io/f4-42.png")), ctx);
        let half_bil = 500000000*OneCoinNineDecimals;
        let staking_rewards_coins = coin::mint<FFIO>(&mut treasury, 8*half_bil, ctx);
        let game_rewards_coins = coin::mint<FFIO>(&mut treasury, 10*half_bil, ctx);
        let presale_coins = coin::mint<FFIO>(&mut treasury, 10*half_bil, ctx);

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

        let team_coins = coin::mint<FFIO>(&mut treasury, 4*half_bil, ctx);
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
            cap: 10*half_bil, // Example cap of 1,000 tokens if TOKEN has 9 decimals
            version: VERSION
        };
        transfer::share_object(presale_state);
    }

    public(package) fun check_version_Treasury(treasury: &Treasury){
        assert!(treasury.version == VERSION, 1);
    }

    public(package) fun check_version_RewardState(rewardState: &RewardState){
        assert!(rewardState.version == VERSION, 1);
    }

    public(package) fun check_version_UserState(userState: &UserState){
        assert!(userState.version == VERSION, 1);
    }

    public(package) fun check_version_PresaleState(presaleState: &PresaleState){
        assert!(presaleState.version == VERSION, 1);
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
    
    /**
    * @notice Stake user specified amount of Sui Coins 
    * @dev This function allows the user to stake a user specified amount of Sui coins 
      and updates their balances and rewards.
    */
    public entry fun stake (payment: Coin<FFIO>, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        check_version_Treasury(treasury);
        let account = tx_context::sender(ctx);
        let totalStakedSupply = balance::value(&treasury.stakedCoinsTreasury);
        let amount = coin::value(&payment);
        // Initialize user mappings if not already present
        if(!vec_map::contains(&userState.balanceOf, &account)){
            vec_map::insert(&mut userState.balanceOf, account, 0);
            vec_map::insert(&mut userState.userRewardPerTokenPaid, account, 0);
            vec_map::insert(&mut userState.rewards, account, 0);
        };
        // Update user and reward state parameters 
        updateReward(totalStakedSupply, account, userState, rewardState, clock);

        // Transfer payment to treasury
        let balance = coin::into_balance(payment);
        balance::join(&mut treasury.stakedCoinsTreasury, balance);

        // Update user's balances
        let balanceOf_account = vec_map::get_mut(&mut userState.balanceOf, &account);
        *balanceOf_account = *balanceOf_account + amount;

        event::emit(Staked{user:tx_context::sender(ctx), amount});
    }

    /**
    * @notice Withdraw the user specified amount of staked Sui coins
    * @dev This function allows the user to withdraw a user specified amount of staked tokens and updates their balances and rewards.
    */
    public entry fun withdraw(userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        check_version_Treasury(treasury);
        let account = tx_context::sender(ctx);
        let balanceOf_account_imut = vec_map::get(&mut userState.balanceOf, &account);
        let totalStakedSupply = balance::value(&treasury.stakedCoinsTreasury);
        // Check if the user has staked tokens
        let userStakedTokensExist = vec_map::contains(&userState.balanceOf, &account);
        assert!(userStakedTokensExist, ENoStakedTokens);
         // Ensure the withdrawal amount is less than the staked balance and greater than zero
        assert!(amount > 0, EZeroAmount);
        assert!(amount <= *balanceOf_account_imut, ERequestedAmountExceedsStaked);
        // Update user and reward state parameters 
        updateReward(totalStakedSupply, account, userState, rewardState, clock);
        // Update user's balance
        let balanceOf_account = vec_map::get_mut(&mut userState.balanceOf, &account);
        *balanceOf_account = *balanceOf_account - amount;
        // Transfer the staked tokens to the user
        let withdrawalAmount = coin::take<FFIO>(&mut treasury.stakedCoinsTreasury, amount, ctx);
        transfer::public_transfer(withdrawalAmount, tx_context::sender(ctx));
        event::emit(Withdrawn{user:tx_context::sender(ctx), amount});
    }

    /**
    * @notice Claim the rewards for the user
    * @dev This function allows the user to claim their rewards and updates their balances and reward states.
    */
    public entry fun getReward(userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock, ctx: &mut TxContext) {
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        check_version_Treasury(treasury);
        let account = tx_context::sender(ctx);
        let totalStakedSupply = balance::value(&treasury.stakedCoinsTreasury);
        // Check if the user has a prior token stake
        let userHasPriorStake = vec_map::contains(&userState.rewards, &account);
        assert!(userHasPriorStake, ENoPriorTokenStake);
        // Check if the user has rewards to claim
        let rewards_account_imut = vec_map::get(&mut userState.rewards, &account);
        assert!(*rewards_account_imut > 0, ENoRewardsToClaim);
        // Update user and reward state parameters 
        updateReward(totalStakedSupply, account, userState, rewardState, clock);
        // Update user's rewards mapping and transfer rewards
        let rewards_account = vec_map::get_mut(&mut userState.rewards, &account);
        let stakingRewards = coin::take<FFIO>(&mut treasury.rewardsTreasury, *rewards_account, ctx);
        event::emit(RewardPaid{user:tx_context::sender(ctx), reward: *rewards_account});
        *rewards_account = 0;
        transfer::public_transfer(stakingRewards, tx_context::sender(ctx));
    }


    /* ========== ADMIN FUNCTIONS ========== */

    /**
    * @notice Set the duration of the reward period
    * @dev This function allows the admin to set the duration of the reward period
    */
    public entry fun setRewardDuration(_: &FindFourAdminCap, rewardState: &mut RewardState, duration: u64, clock: &Clock) {
         check_version_RewardState(rewardState);
        // Ensure that the reward duration has expired
        assert!(rewardState.finishAt < clock::timestamp_ms(clock), ERewardDurationNotExpired);
        rewardState.duration = duration;
        event::emit(RewardDurationUpdated{newDuration: duration});
    }

    public entry fun update_version(_: &FindFourAdminCap, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, presaleState: &mut PresaleState) {
        userState.version = VERSION;
        rewardState.version = VERSION;
        treasury.version = VERSION;
        presaleState.version = VERSION;
    }

    /**
    * @notice Set the amount and consequently the rate of the reward
    * @dev This function allows the admin to set the amount and as a result the rate of the reward, updates user and reward states
    */
    public entry fun setRewardAmount(_: &FindFourAdminCap, reward: Coin<FFIO>, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, clock: &Clock) {
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        check_version_Treasury(treasury);
        let totalStakedSupply = balance::value(&treasury.stakedCoinsTreasury);
        let amount = coin::value(&reward);
        // Update user and reward state parameters 
        updateReward(totalStakedSupply, @0x0, userState, rewardState, clock);
        // Add rewards to treasury
        let balance = coin::into_balance(reward);
        balance::join(&mut treasury.rewardsTreasury, balance);
        // Compute the reward rate
        if(clock::timestamp_ms(clock) >= rewardState.finishAt){
            rewardState.rewardRate = amount / rewardState.duration;
        }
        else{
            let remaining_reward = (rewardState.finishAt - clock::timestamp_ms(clock)) * rewardState.rewardRate;
            rewardState.rewardRate = (amount + remaining_reward) / rewardState.duration;
        };
        // Ensure that the reward rate has been computed correctly
        assert!(rewardState.rewardRate > 0, EZeroRewardRate);
        assert!(rewardState.rewardRate * rewardState.duration <= balance::value(&treasury.rewardsTreasury), ELowRewardsTreasuryBalance);
        // Update the Last Updated Time and Finish Time
        rewardState.finishAt = clock::timestamp_ms(clock) + rewardState.duration;
        rewardState.updatedAt = clock::timestamp_ms(clock);
        event::emit(RewardAdded{reward: amount});
    }


    /* ========== HELPER FUNCTIONS ========== */

    /**
    * @notice Update the reward for a specific user 
    * @dev This function calculates and updates the reward for a specific user based on the total staked supply and reward state parameters.
    */
    fun updateReward(totalStakedSupply: u64, account: address, userState: &mut UserState, rewardState: &mut  RewardState, clock :&Clock){
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        // Calculate rewardPerTokenStored
        userState.rewardPerTokenStored = rewardPerToken(totalStakedSupply, userState, rewardState, clock);
        // Update the Last Updated Time
        rewardState.updatedAt = math::min(clock::timestamp_ms(clock), rewardState.finishAt); // lastTimeRewardApplicable
        if (account != @0x0){
            // Update the user's rewards earned
            let new_reward_value = earned(totalStakedSupply, account, userState, rewardState, clock);
            let rewards_account = vec_map::get_mut(&mut userState.rewards, &account);
            *rewards_account = new_reward_value;

            // Update the user's userRewardPerTokenPaid
            let userRewardPerTokenPaid_account = vec_map::get_mut(&mut userState.userRewardPerTokenPaid, &account);
            *userRewardPerTokenPaid_account = userState.rewardPerTokenStored;
        }
    }

    /**
    * @notice Calculate the rewards earned for a specific user
    * @dev This function calculates the rewards earned for a specific user based on the total staked supply and reward state parameters.
    */
    fun earned(totalStakedSupply: u64, account: address, userState: &UserState, rewardState: &RewardState, clock: &Clock): u64{
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        // Typecast to u256 to avoid arithmetic overflow
        let balanceOf_account = (*vec_map::get(&userState.balanceOf, &account) as u256);
        let userRewardPerTokenPaid_account = (*vec_map::get(&userState.userRewardPerTokenPaid, &account) as u256);
        let rewards_account = (*vec_map::get(&userState.rewards, &account) as u256);
        let token_decimals = (math::pow(10, 9) as u256);
        // Update the rewards earned
        let rewards_earned  = ((balanceOf_account * ((rewardPerToken(totalStakedSupply, userState, rewardState, clock) as u256) - userRewardPerTokenPaid_account)) / token_decimals) + rewards_account;
        return (rewards_earned as u64)
    }

    /**
    * @notice Calculate the reward per token at time t
    * @dev This function calculates the reward per token at time t based on the total staked supply and reward state parameters.
    */
    fun rewardPerToken(totalStakedSupply: u64, userState: &UserState, rewardState: &RewardState, clock: &Clock): u64 {
        check_version_UserState(userState);
        check_version_RewardState(rewardState);
        if (totalStakedSupply == 0) { 
            return userState.rewardPerTokenStored
        };
        let token_decimals = (math::pow(10, 9) as u256);
        let lastTimeRewardApplicable = (math::min(clock::timestamp_ms(clock), rewardState.finishAt) as u256);
        // Typecast to u256 to avoid arithmetic overflow
        let computedRewardPerToken = (userState.rewardPerTokenStored as u256) + ((rewardState.rewardRate as u256) * (lastTimeRewardApplicable - (rewardState.updatedAt as u256)) * token_decimals)/ (totalStakedSupply as u256);
        return (computedRewardPerToken as u64)
    }


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
        // let total_cost = amount * presale.price;
        // assert!(balance::value(coin::balance_mut(payment)) >= total_cost, 0); // Ensure enough payment
        // assert!(presale.tokens_sold + amount <= presale.cap, 1); // Ensure we don't exceed cap
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

    // Function to end presale and return remaining tokens to owner
    // public entry fun end_presale(presale: &mut PresaleState, ctx: &mut TxContext) {
    //     let PresaleState { id, total_supply, price: _, tokens_sold: _, cap: _ } = presale;
    //     object::delete(id);
    //     let remaining = coin::mint(&mut total_supply, balance::supply_value(&total_supply), ctx);
    //     transfer::transfer(remaining, tx_context::sender(ctx));
    // }
// }


}