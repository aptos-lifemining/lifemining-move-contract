module deployer::DynamicProfile {
    use std::string;
    use std::string::String;

    use std::signer;
    use aptos_token::token;

    use aptos_token::token::TokenDataId;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;

    // Stored in Resource Account
    struct ModuleSignerData has key {
        signer_cap: SignerCapability,
    }

    // Stored in User Account
    struct ModuleTokenData has key {
        token_data_id: TokenDataId,
    }

    // Create collection during deployment
    fun init_module(resource_signer: &signer) {
        let collection_name = string::utf8(b"LifeMining Profile Collection V1");
        let description = string::utf8(b"Profile NFT collection for LifeMining app: V1");
        let collection_uri = string::utf8(b"https://lifemining.app");

        let maximum_supply = 0; // unlimited
        let collection_mutate_setting = vector<bool>[ false, false, false ]; // description, uri, maximum_supply

        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, collection_mutate_setting);

        // Store the signer capability in the module data
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);
        move_to(
            resource_signer,
            ModuleSignerData {
                signer_cap: resource_signer_cap,
            },
        );
    }

    // Create a new profile Token for user, with mutability on tokendata uri
    fun create_profile_token(resource_signer: &signer, user: &signer, token_name: String, token_uri: String) {
        let token_data_id = token::create_tokendata(
            resource_signer, // account(signer)
            string::utf8(b"LifeMining Profile Collection V1"), // collection name
            token_name, // token name
            string::utf8(b"LifeMining User Profile Token"), // description
            0, // maximum
            token_uri, // token uri
            signer::address_of(resource_signer), // royalty_payee_address
            1, // royalty_points_denominator
            0, // royalty_points_numerator
            token::create_token_mutability_config( // token_mutate_config
                &vector<bool>[ false, true, false, false, false ] // maximum, uri, royalty, description, properties
            ),
            // We can use property maps to record attributes related to the token.
            // In this example, we are using it to record the receiver's address.
            // We will mutate this field to record the user's address
            // when a user successfully mints a token in the `mint_event_ticket()` function.
            vector<String>[string::utf8(b"")], // property_keys
            vector<vector<u8>>[], // property_values
            vector<String>[string::utf8(b"address")], // property_types
        );

        // mint token to user
        let token_id = token::mint_token(resource_signer, token_data_id, 1); // account, dataId, amount
        token::direct_transfer(resource_signer, user, token_id, 1); // sender, receiver, tokenId, amount

        // Store the token data id in the user's account
        move_to(
            user,
            ModuleTokenData {
                token_data_id: token_data_id,
            });
    }

    // mutate tokendata uri
    fun mutate_profile_token_uri(resource_signer: &signer, token_data_id: TokenDataId, new_uri: String) {
        token::mutate_tokendata_uri(resource_signer, token_data_id, new_uri); // creator, tokenDataId, newURI
    }
    // entry function for user to create a profile token and mutate its uri
    public entry fun create_or_mutate_profile_token(user: &signer, uri: String, userName: String, option: String) acquires ModuleSignerData, ModuleTokenData {

        let module_signer_data = borrow_global_mut<ModuleSignerData>(@deployer);
        // let module_signer_data = borrow_global_mut<ModuleSignerData>(account::get_resource_account_address());
        let resource_signer = account::create_signer_with_capability(&module_signer_data.signer_cap);

        if (option == string::utf8(b"create")) {
            let tokenName = userName;
            create_profile_token(&resource_signer, user, tokenName, uri); // resource_signer, user, collection_name, token_name, token_uri
        } else if (option == string::utf8(b"mutate")) {
            let user_address = signer::address_of(user);
            let module_token_data = borrow_global_mut<ModuleTokenData>(user_address);
            let module_token_data_id = module_token_data.token_data_id;
            mutate_profile_token_uri(&resource_signer, module_token_data_id, uri);
        } else {
            abort(99)
        }
    }
}
