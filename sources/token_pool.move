module find_four::FFIO {
    use sui::coin::{Self, Coin, value, TreasuryCap};
    use sui::table::{new, add, contains, borrow_mut};
    use sui::url::Url;

    const REWARD_ALREADY_CLAIMED: u64 = 6; 
    const INSUFFICIENT_POOL_BALANCE: u64 = 7; 

    public struct FFIO has drop {}


    public struct RewardAccount has key, store {
        id: UID,
        rewards: vector<TokenReward>,
    }

    public struct TokenReward has store, copy, drop {
        amount: u64,
        claimed: bool,
    }

    /// A shared pool that holds a list of coins for rewards
    public struct RewardPool has key {
        id: UID,
        coins: vector<Coin<FFIO>>,  // A vector of coins that makes up the pool
    }

    public(package) fun create_url(url: vector<u8>): Url {
        let url = sui::url::new_unsafe(std::ascii::string(url));
        url
    }

    fun init(witness: FFIO, ctx: &mut TxContext) {
        let (mut treasury, metadata) = coin::create_currency(witness, 6, b"FFIO", b"Find4.io Coin", b"Play to earn!", option::some(create_url(b"https://www.shutterstock.com/image-photo/game-4-row-yellow-red-600nw-2233654429.jpg")), ctx);
        let trea = &mut treasury;
        mint_ffio(trea, 100, ctx.sender(), ctx);
        let init_coin = coin::mint<FFIO>(&mut treasury, 100, ctx);
        let mut coins = vector::empty<Coin<FFIO>>();
        vector::push_back(&mut coins, init_coin);
        create_reward_pool(coins, ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender());
    }

    public(package) fun mint_ffio(
        treasury_cap: &mut TreasuryCap<FFIO>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Creates a new reward account
    public fun create_reward_account(ctx: &mut TxContext) {
        let reward_account = RewardAccount {
            id: object::new(ctx),
            rewards: vector::empty<TokenReward>(),
        };
        transfer::public_transfer(reward_account, ctx.sender());
    }

    /// Creates a pool for holding tokens that will be used to reward players
    public fun create_reward_pool(coins: vector<Coin<find_four::FFIO::FFIO>>, ctx: &mut TxContext) {
        let reward_pool = RewardPool {
            id: object::new(ctx),
            coins,  // The coins passed in are stored in the pool
        };
        transfer::share_object(reward_pool);
    }

    /// Check the total balance of the pool by summing all coin values
    public fun total_pool_balance(pool: &mut RewardPool): u64 {
        let mut total: u64 = 0;
        let len = vector::length(&pool.coins);
        let mut i = 0;
        while (i < len) {
            let coin = vector::borrow(&pool.coins, i);
            total = total + value(coin);
            i = i + 1;
        };
        total
    }

    /// Automatically adds a reward when a player wins a game, drawing from the reward pool
    public fun reward_winner(
        pool: &mut RewardPool, 
        account: &mut RewardAccount,
        amount: u64
    ) {
        let total_balance = total_pool_balance(pool);
        assert!(total_balance >= amount, INSUFFICIENT_POOL_BALANCE);

        let reward = TokenReward {
            amount: amount,
            claimed: false,
        };

        // Add reward to the player's account
       
            // let mut rewards = vector::empty<TokenReward>();
            // vector::push_back(&mut rewards, reward);
            // add(&mut account.rewards, rewards);
            // let rewards = vector::borrow_mut(&mut account.rewards);
            vector::push_back(&mut account.rewards, reward);

        // Deduct the reward from the pool by splitting coins
        // let mut remaining_amount = amount;
        // let mut i = 0;
        // while (remaining_amount > 0) {
        //     let coin = vector::borrow_mut(&mut pool.coins, i);
        //     let coin_value = value(coin);

        //     if (coin_value <= remaining_amount) {
        //         remaining_amount = remaining_amount - coin_value;
        //         // Transfer full coin
        //         vector::remove(&mut pool.coins, i);
        //     } else {
        //         let remaining_coin = split(coin, remaining_amount, ctx);
        //         remaining_amount = 0;
        //         // Replace original coin with remaining coin
        //         vector::remove(&mut pool.coins, i);
        //         vector::push_back(&mut pool.coins, remaining_coin);
        //     };
        //     i = i + 1;
        // };
    }

    /// Player claims a specific reward from their account
    public fun claim_reward(
        pool: &mut RewardPool,
        account: &mut RewardAccount, 
        index: u64,
        ctx: &mut TxContext
    ) {
        // let rewards = vector::borrow_mut(&mut account.rewards);
        let reward = vector::borrow_mut(&mut account.rewards, index);

        assert!(!reward.claimed, REWARD_ALREADY_CLAIMED);

        // Ensure the pool has enough balance for the claim
        let total_balance = total_pool_balance(pool);
        assert!(total_balance >= reward.amount, INSUFFICIENT_POOL_BALANCE);

        // Deduct the reward from the pool and transfer to player
        let mut remaining_amount = reward.amount;
        let mut i = 0;
        while (remaining_amount > 0) {
            let coinr = vector::borrow_mut(&mut pool.coins, i);
            let coin_value = coinr.value();

            // if (coin_value <= remaining_amount) {
            //     remaining_amount = remaining_amount - coin_value;
            //     transfer::transfer(*coin, player);  // Transfer full coin
            //     vector::remove(&mut pool.coins, i);
            // } else {
            //     let (claim_coin, remaining_coin) = split(coin, remaining_amount, ctx);
            //     remaining_amount = 0;
            //     transfer(claim_coin, player);  // Transfer the reward portion
            //     // Replace original coin with remaining balance
            //     vector::remove(&mut pool.coins, i);
            //     vector::push_back(&mut pool.coins, remaining_coin);
            // };
            if (coin_value <= remaining_amount) {
                remaining_amount = remaining_amount - coin_value;
                // Transfer full coin
                // let tcoin = vector::
                // let coin_option = vector::borrow_mut(&mut pool.coins, index);
                // let coin = option::take(coin_option).unwrap();
                // let coinr2 = vector::remove(&mut pool.coins, i);
                // let n = coin::
                let new_coin = coin::split(coinr, coin_value, ctx);
                transfer::public_transfer(new_coin, ctx.sender());
            } else {
                // let cc = &mut coinr;
                let new_coin = coin::split(coinr, remaining_amount, ctx);
                remaining_amount = 0;
                // Replace original coin with remaining coin
                // vector::remove(&mut pool.coins, i);
                // vector::push_back(&mut pool.coins, coinr);
                // let coinr2 = vector::remove(&mut pool.coins, i);
                transfer::public_transfer(new_coin, ctx.sender());
            };
            i = i + 1;
        };

        reward.claimed = true;
    }
}