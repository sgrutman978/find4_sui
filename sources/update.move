module find_four::update {

    use find_four::FFIO::{FindFourAdminCap, UserState, RewardState, Treasury, PresaleState};
    use find_four::multi_player::{FFIO_Nonce};
    use find_four::profile_and_rank::{ProfileTable};
    // GAMEBOARD ALSO HAS AN UPDATE FUNCTION BUT IT WILL LIKELY NEVER USED TO UPDATE SPECIFIC GAMES

    public entry fun updateAll(cap: &FindFourAdminCap, userState: &mut UserState, rewardState: &mut RewardState, treasury: &mut Treasury, presaleState: &mut PresaleState, nonce: &mut FFIO_Nonce, profileTable: &mut ProfileTable){
        find_four::FFIO::update_version(cap, userState, rewardState, treasury, presaleState);
        find_four::multi_player::update_version(cap, nonce);
        find_four::profile_and_rank::update_version(cap, profileTable);
    }

}