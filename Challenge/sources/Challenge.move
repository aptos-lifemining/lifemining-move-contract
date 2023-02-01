// module resource_account::Challenge {

//     use std::vector;
//     use std::signer;
//     use aptos_framework::resource_account;
//     use aptos_framework::timestamp;
//     use aptos_framework::account::SignerCapability;

//     // TODO: How to map the ChallengeInfo to a certain UserChallengeRecord?
//     // TODO: to store the challenge records to the user's account?

//     struct ModuleData has key {
//         signer_cap: SignerCapability,
//     }

//     // Stored in the resource account???
//     struct ChallengeStore has key {
//         challenge_host: address,
//         challenge_is_active: bool,
//         challenge_start_time: u64,
//         challenge_period: u64, // e.g. 7 days
//         user_challenge_record_store: vector<UserChallengeRecord>
//         // TODO: related resource accounts (e.g. Staking, Certificate)
//     }

//     struct UserChallengeRecord has key {
//         user: address, // key
//         challenge_daily_checkpoints: vector<bool>, // value; (e.g. [true, false, true, false, true, false, true])
//         challenge_completed: bool, // set default as false
//     }

//     // fun init_module(resource_signer: &signer, challenge_host: address, challenge_period: u64) {
//     fun init_module(resource_signer: &signer) {

//         // resource account signer capability
//         let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

//         // create a new challenge
//         let new_challenge = ChallengeStore {
//             challenge_host: @resource_account,
//             // challenge_host: challenge_host,
//             challenge_is_active: true,
//             challenge_start_time: timestamp::now_seconds(),
//             challenge_period: 7,
//             // challenge_period: challenge_period,
//             user_challenge_record_store: vector::empty<UserChallengeRecord>(),
//         };
        
//         // Move resource ownership to the resource account
//         move_to(resource_signer, new_challenge);
//     }

//     // fun get_challenge_info() {}

//     public entry fun initiate_user_challenge(user: &signer) acquires ChallengeStore {
//         let challenge = borrow_global_mut<ChallengeStore>(@resource_account);
//         let user_challenge_record = UserChallengeRecord {
//             user: signer::address_of(user),
//             challenge_daily_checkpoints: vector::empty<bool>(),
//             challenge_completed: false,
//         };
//         vector::push_back(&mut challenge.user_challenge_record_store, user_challenge_record);
//     }

//     public entry fun add_user_challenge_record(_user: &signer, success: bool) acquires ChallengeStore {
//         let challenge = borrow_global_mut<ChallengeStore>(@resource_account);
//         let user_challenge_record = vector::borrow_mut(&mut challenge.user_challenge_record_store, 0); // how to get specific user's index of the struct in the vector<UserChallengeRecord>
//         vector::push_back(&mut user_challenge_record.challenge_daily_checkpoints, success);
//     }

// }