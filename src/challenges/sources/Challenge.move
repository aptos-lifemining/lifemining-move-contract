module challenge_admin_resource_account::Challenge {

    use std::error;
    use std::vector;
    use std::signer;
    use std::string::String;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;
    use aptos_framework::account::SignerCapability;

    /*
    ** functions
    ** <host>
    ** - create_challenge
    ** - start_challenge
    ** - finish_challenge
    ** <participant>
    ** - join_challenge
    ** - submit_daily_checkpoint
    */

    // Error codes
    const EINVALID_TIMESTAMP: u64 = 0;
    const EINVALID_CHALLENGE_STATUS: u64 = 1;

    // Challenge status
    const CHALLENGE_CREATED: u64 = 0;
    const CHALLENGE_STARTED: u64 = 1;
    const CHALLENGE_FINISHED: u64 = 2;

    // structs for the resource account

    struct SignerStore has key {
        signer_cap: SignerCapability,
    }

    struct LifeMiningChallenges has key {
        challenges: SimpleMap<ChallengeDataId, ChallengeData>,
    }

    struct ChallengeDataId has store, copy, drop{
        challenge_host: address,
        challenge_code_id: String,
    }

    struct ChallengeData has store {
        challenge_status: u64, // enum { 0, 1, 2, 3 }
        deposit_amount: u64, // amount in APT coin
        challenge_period_in_days: u64,
        success_threshold_in_days: u64,
        start_time: u64,
        end_time: u64,
        participants: vector<address>,
        succeeded_participants: vector<address>,
        final_reward_for_successful_participants: u64,
    }

    // structs for user accounts

    // Challenge resources owned by participants
    struct ChallengeStoreForParticipants has key {
        challenges_for_participants: SimpleMap<ChallengeId, Challenge>,
    }

    struct ChallengeId has store, copy, drop {
        challenge_data_id: ChallengeDataId,
    }

    struct Challenge has store {
        challenge_id: ChallengeId,
        daily_checkpoints: SimpleMap<u64, bool>, // <day_index, successful>
        success_counter: u64,
        done_claim_for_reward: bool,
    }

    struct ChallengeStoreForHosts has key {
        challenges_for_hosts: vector<ChallengeId> // no checkpoints needed for hosts
        // TODO: any additional resources hosts must manage?
    }

    // Initialize the Resource Account

    fun init_module(resource_signer: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

        move_to(resource_signer, SignerStore{
            signer_cap: signer_cap,
        });

        move_to(resource_signer, LifeMiningChallenges{
            challenges: simple_map::create<ChallengeDataId, ChallengeData>(),
        });

        // Initialize the Vault module

        challenge_admin_resource_account::Vault::init_vault(resource_signer);
    }

    fun check_timestamp(start_time: u64, end_time: u64): bool {
        let current_time = timestamp::now_seconds();
        if (current_time >= start_time && current_time <= end_time) {
            true
        } else {
            false
        }
    }

    // Functions for the challenge hosts

    // Initialize the challenge host account
    public fun initialize_host(account: &signer) {
        if (!exists<ChallengeStoreForHosts>(signer::address_of(account))) {
            move_to(
                account,
                ChallengeStoreForHosts {
                    challenges_for_hosts: vector::empty<ChallengeId>(),
                },
            );
        }
    }

    public entry fun create_challenge(
        host: &signer,
        challenge_code_id: String,
        deposit_amount: u64,
        challenge_period_in_days: u64,
        success_threshold_in_days: u64,
        start_time: u64,
        end_time: u64,
    ) acquires LifeMiningChallenges, ChallengeStoreForHosts {

        // mutate the resource account state

        let challenge_data_id = ChallengeDataId {
            challenge_host: signer::address_of(host),
            challenge_code_id: challenge_code_id,
        };

        let challenge_data = ChallengeData {
            challenge_status: CHALLENGE_CREATED, // 0
            deposit_amount: deposit_amount,
            challenge_period_in_days: challenge_period_in_days,
            success_threshold_in_days: success_threshold_in_days,
            start_time: start_time,
            end_time: end_time,
            participants: vector::empty<address>(),
            succeeded_participants: vector::empty<address>(),
            final_reward_for_successful_participants: 0, // initialize to 0
        };

        let challenges = &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges;
        simple_map::add(challenges, challenge_data_id, challenge_data);

        // mutate the host account state

        initialize_host(host);

        let challenge_id = ChallengeId {
            challenge_data_id: challenge_data_id,
        };

        let challenges_for_hosts = &mut borrow_global_mut<ChallengeStoreForHosts>(signer::address_of(host)).challenges_for_hosts;
        vector::push_back(challenges_for_hosts, challenge_id);
    }

    public entry fun start_challenge(
        host: &signer,
        challenge_code_id: String
    ) acquires LifeMiningChallenges {

        let challenge_data = simple_map::borrow_mut(
            &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges,
            &ChallengeDataId {
                challenge_host: signer::address_of(host),
                challenge_code_id: challenge_code_id,
            },
        );

        assert!(check_timestamp(challenge_data.start_time, challenge_data.end_time), error::aborted(EINVALID_TIMESTAMP));

        challenge_data.challenge_status = CHALLENGE_STARTED; // 1
    }

    // mutate: ChallengeData.is_active = false
    // transfer APT coin in the challenge vault to the succeeded participants
    public entry fun finish_challenge(
        host: &signer,
        challenge_code_id: String
    ) acquires LifeMiningChallenges {

        let challenge_data = simple_map::borrow_mut(
            &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges,
            &ChallengeDataId {
                challenge_host: signer::address_of(host),
                challenge_code_id: challenge_code_id,
            },
        );

        // Distribute the reward to the succeeded participants
        let participants = &challenge_data.participants;
        let succeeded_participants = &challenge_data.succeeded_participants;
        // total deposit amount
        let total_deposit = challenge_data.deposit_amount * vector::length(participants);
        let reward_amount = total_deposit / vector::length(succeeded_participants);
        challenge_data.final_reward_for_successful_participants = reward_amount;

        // let i = 0;
        // while (i < vector::length(succeeded_participants)) {
        //     challenge_admin_resource_account::Vault::unstake_from_vault(*vector::borrow(succeeded_participants, i), reward_amount);
        //     i = i + 1;
        // };

        assert!(timestamp::now_seconds() >= challenge_data.end_time, error::aborted(EINVALID_TIMESTAMP));
        challenge_data.challenge_status = CHALLENGE_FINISHED; // 2
    }

    
    // Functions for challenge participants

    // Initialize the challenge participant account
    public fun initialize_participant(account: &signer) {
        if (!exists<ChallengeStoreForParticipants>(signer::address_of(account))) {
            move_to(
                account,
                ChallengeStoreForParticipants {
                    challenges_for_participants: simple_map::create<ChallengeId, Challenge>(),
                },
            );
        }
    }

    public entry fun join_challenge(
        participant: &signer,
        host_address: address,
        challenge_code_id: String
    ) acquires LifeMiningChallenges, ChallengeStoreForParticipants {

        // mutate the resource account state

        let challenge_data_id = ChallengeDataId {
            challenge_host: host_address,
            challenge_code_id: challenge_code_id,
        };

        // mutate ChallengeData.participants (add the participant address)
        let challenge_data = simple_map::borrow_mut(
            &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges,
            &challenge_data_id,
        );

        // staking: transfer APT coin from the participant account to the challenge vault 
        challenge_admin_resource_account::Vault::stake_to_vault(participant, challenge_data.deposit_amount);

        // assert if the challenge is created or started
        let status = challenge_data.challenge_status;
        assert!((status == CHALLENGE_CREATED || status == CHALLENGE_STARTED), EINVALID_CHALLENGE_STATUS);

        vector::push_back(&mut challenge_data.participants, signer::address_of(participant));

        // mutate the participant account state

        initialize_participant(participant);

        let challenge_id = ChallengeId {
            challenge_data_id: challenge_data_id,
        };

        let challenges_for_participants = &mut borrow_global_mut<ChallengeStoreForParticipants>(signer::address_of(participant)).challenges_for_participants;

        simple_map::add(
            challenges_for_participants,
            challenge_id,
            Challenge {
                challenge_id: challenge_id,
                daily_checkpoints: simple_map::create<u64, bool>(),
                success_counter: 0,
                done_claim_for_reward: false,
            }
        );
    }

    public entry fun submit_daily_checkpoint(
        participant: &signer,
        host_address: address,
        challenge_code_id: String,
        day_index: u64
    ) acquires ChallengeStoreForParticipants, LifeMiningChallenges {

        let challenge_data_id = ChallengeDataId {
            challenge_host: host_address,
            challenge_code_id: challenge_code_id,
        };

        let challenge_data = simple_map::borrow_mut(
            &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges,
            &challenge_data_id,
        );

        // assert if the challenge is started
        let status = challenge_data.challenge_status;
        assert!(status == CHALLENGE_STARTED, EINVALID_CHALLENGE_STATUS);


        let challenge_id = ChallengeId {
            challenge_data_id: challenge_data_id,
        };

        let challenge = simple_map::borrow_mut(
            &mut borrow_global_mut<ChallengeStoreForParticipants>(signer::address_of(participant)).challenges_for_participants,
            &challenge_id,
        );

        simple_map::add(&mut challenge.daily_checkpoints, day_index, true);
        challenge.success_counter = challenge.success_counter + 1; // increment the counter

        if (challenge.success_counter == challenge_data.success_threshold_in_days) { // added to the succeeded participants when the counter reaches the threshold (executed once)
            vector::push_back(&mut challenge_data.succeeded_participants, signer::address_of(participant));
        }
    }

    public entry fun claim_for_challenge_reward(
        participant: &signer,
        host_address: address,
        challenge_code_id: String,
    ) acquires LifeMiningChallenges, ChallengeStoreForParticipants {

        let challenge_data_id = ChallengeDataId {
            challenge_host: host_address,
            challenge_code_id: challenge_code_id,
        };

        let challenge_data = simple_map::borrow_mut(
            &mut borrow_global_mut<LifeMiningChallenges>(@challenge_admin_resource_account).challenges,
            &challenge_data_id,
        );

        assert!(challenge_data.challenge_status == CHALLENGE_FINISHED, EINVALID_CHALLENGE_STATUS); // could be claimed only when the challenge is finished

        let challenge_id = ChallengeId {
            challenge_data_id: challenge_data_id,
        };

        let challenge = simple_map::borrow_mut(
            &mut borrow_global_mut<ChallengeStoreForParticipants>(signer::address_of(participant)).challenges_for_participants,
            &challenge_id,
        );

        // if the participant is in the succeeded participants, distribute the reward
        let succeeded_participants = &challenge_data.succeeded_participants;
        if (vector::contains(succeeded_participants, &signer::address_of(participant))) {
            challenge_admin_resource_account::Vault::unstake_from_vault(signer::address_of(participant), challenge_data.final_reward_for_successful_participants);
            challenge.done_claim_for_reward = true;
        }
    }
}
