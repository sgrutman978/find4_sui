module MyToken {
    use sui::object::ID;

    public struct FFIO_TOKEN has store, key {
        id: UID,
    }

    public fun create_token(ctx: &mut TxContext): Coin<MYTOKEN> {
        let id = ID::new(ctx);
        let token = MYTOKEN { id };
        Coin::create(token, 1000)  // Creating a token with some initial value
    }

    fun init(witness: FFIO_TOKEN, ctx: &mut TxContext) {
        let (mut treasury, metadata) = create_currency(witness, 6, b"RPSLSC", b"Rock Paper Scissors Lizard Spock Coin", b"Play to earn!", option::some(create_url(b"https://i0.wp.com/puzzlewocky.com/wp-content/uploads/2016/10/RockPaperScissorsLizardSpock.jpg")), ctx);
        let trea = &mut treasury;
        mint_ffio(trea, 100, ctx.sender(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender());
    }

    public fun mint_ffio(
        treasury_cap: &mut TreasuryCap<FFIO_TOKEN>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext,
    ) {
        let coin = mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient)
    }
}