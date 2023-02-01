module challenge_admin_resource_account::Challenge {
    use std::vector;
    use std::signer;
    use std::string::String;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::resource_account;
    use aptos_framework::account::SignerCapability;

    /*
    ** functions
    ** <host>
    ** - create_challenge
    ** - start_challenge
    ** - end_challenge
    ** - withdraw_challenge
    ** <participant>
    ** - join_challenge
    ** - withdraw_challenge
    ** - submit_checkpoint
    */


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
        is_active: bool,
        deposit_amount: u64, // amount in APT coin
        challenge_period_in_days: u64,
        start_time: u64,
        participants: vector<address>,
        succeeded_participants: vector<address>,
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
        checkpoints: SimpleMap<u64, bool> // <day_index, successful>
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
        start_time: u64,
    ) acquires LifeMiningChallenges, ChallengeStoreForHosts {

        // mutate the resource account state

        let challenge_data_id = ChallengeDataId {
            challenge_host: signer::address_of(host),
            challenge_code_id: challenge_code_id,
        };

        let challenge_data = ChallengeData {
            is_active: false,
            deposit_amount: deposit_amount,
            challenge_period_in_days: challenge_period_in_days,
            start_time: start_time,
            participants: vector::empty<address>(),
            succeeded_participants: vector::empty<address>(),
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

        // let module_data = borrow_global_mut<SignerStore>(@resourcre_account);
        // let signer_cap = &mut module_data.signer_cap;
        // signer_cap.borrow_signer();
    }

    // mutate: ChallengeData.is_active = true
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
        challenge_data.is_active = true;
        // let module_data = borrow_global_mut<SignerStore>(0x1);
        // let signer_cap = &mut module_data.signer_cap;
        // signer_cap.borrow_signer();
    }

    // mutate: ChallengeData.is_active = false
    // transfer APT coin in the challenge vault to the succeeded participants
    public entry fun end_challenge(
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
        challenge_data.is_active = false;

        // TODO: transfer APT coin in the challenge vault to the succeeded participants        

        // let module_data = borrow_global_mut<SignerStore>(0x1);
        // let signer_cap = &mut module_data.signer_cap;
        // signer_cap.borrow_signer();
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

        // assert if the challenge is active
        // FIXME: wrong conditions. 
        assert!(challenge_data.is_active, 0); // TODO: error code
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
                checkpoints: simple_map::create<u64, bool>(),
            }
        );

        // let module_data = borrow_global_mut<SignerStore>(0x1);
        // let signer_cap = &mut module_data.signer_cap;
        // signer_cap.borrow_signer();
    }

    public entry fun submit_checkpoint(
        participant: &signer,
        host_address: address,
        challenge_code_id: String,
        day_index: u64
    ) acquires ChallengeStoreForParticipants {

        let challenge_data_id = ChallengeDataId {
            challenge_host: host_address,
            challenge_code_id: challenge_code_id,
        };

        let challenge_id = ChallengeId {
            challenge_data_id: challenge_data_id,
        };

        let challenge = simple_map::borrow_mut(
            &mut borrow_global_mut<ChallengeStoreForParticipants>(signer::address_of(participant)).challenges_for_participants,
            &challenge_id,
        );

        simple_map::add(&mut challenge.checkpoints, day_index, true)
        // let module_data = borrow_global_mut<SignerStore>(0x1);
        // let signer_cap = &mut module_data.signer_cap;
        // signer_cap.borrow_signer();
    }

    // public fun withdraw(challenge_code_id: String) acquires LifeMiningChallenges, SignerStore {
    //     let participant = Signer::address_of(signer);
    //     let host = Signer::address_of(signer);
    //     let challenge_data_id = ChallengeDataId {
    //         challenge_host: host,
    //         challenge_code_id: challenge_code_id,
    //     };
    //     let challenges = &mut borrow_global_mut<LifeMiningChallenges>(0x1).challenges;
    //     let challenge_data = challenges.get_mut(&challenge_data_id);
    //     let challenge_id = ChallengeId {
    //         challenge_data_id: challenge_data_id,
    //     };
    //     let challenge = &mut borrow_global_mut<ChallengeStoreForParticipants>(participant).challenges_for_participants.get_mut(&challenge_id);
    //     let checkpoints = &challenge.checkpoints;
    //     let mut success_count = 0;
    //     let mut day_index = 0;
    //     while (day_index < challenge_data.challenge_period_in_days) {
    //         if (checkpoints.get(&day_index) == true) {
    //             success_count = success_count + 1;
    //         }
    //         day_index = day_index + 1;
    //     }
    //     if (success_count == challenge_data.challenge_period_in_days) {
    //         challenge_data.succeeded_participants.push_back(participant);
    //     }
    //     // let module_data = borrow_global_mut<SignerStore>(0x1);
    //     // let signer_cap = &mut module_data.signer_cap;
    //     // signer_cap.borrow_signer();
    // }



}
