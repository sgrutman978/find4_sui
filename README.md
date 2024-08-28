# Player initialize game
sui client ptb --move-call 0xad85e272ff312c52cd26688d26dff413ebb464f239baa84b21cf697fd4645f76::find_four_game::initialize_game @0xcf8f56cf14a342acd2eaea003b2337d5bbc3e9ddfcbdb17c5fda1ac957ad7b99 --gas-budget 20000000  

# Player Make Move
sui client ptb --move-call <--program_address-->::find_four_game::player_move <--game_object_id--> <--column_num--> --gas-budget 20000000

# Other useful Sui command examples

sui move test

sui client addresses

sui client upgrade --upgrade-capability 0x367b0aa0ffbf73ea1c58018c5602d01b71b0efaa6ceb96a1095f5f1c693735ff --skip-dependency-verification

sui client switch --address owner

sui client publish --gas-budget 50000000

curl --location --request POST 'https://faucet.devnet.sui.io/gas' \
--header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "0xcf8f56cf14a342acd2eaea003b2337d5bbc3e9ddfcbdb17c5fda1ac957ad7b99"
    }
}'

sui client ptb --move-call 0x70aaf93346c0881dc04382369ba289cf584317537228616c001666c56a6ee269::my_module::hard_reset @0x5e66e680c327012e8085cd9d73d5171f65dc66ce626d022f637c89f2b3368836 --gas-budget 20000000

sui client ptb --move-call 0x8d6b6ce6f4dd3406bc74008d06e9e7f7584c9c17db4b51fea8204a8efad19cc7::my_module::do_1st_shoot @0xc2a0f28a2efacd56e96fdd638f0702d63b11bfd756bb6487fdeb2bde723ea084 '"47ea70cf08872bdb4afad3432b01d963ac7d165f6b575cd72ef47498f4459a90"' --gas-budget 20000000

sui keytool import <--address--> ?ed25519?

sui keytool update-alias stupefied-hiddenite real1
