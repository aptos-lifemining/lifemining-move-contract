module resource_account::Staking {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::coin;
    use aptos_framework::resource_account;
    use aptos_framework::aptos_coin::{AptosCoin};

    struct ModuleData has key {
        signer_cap: SignerCapability,
    }

    fun init_module(resource_signer: &signer) {
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

        move_to(resource_signer, ModuleData{
            signer_cap: resource_signer_cap,
        });

        coin::register<AptosCoin>(resource_signer);
    }
 
    public entry fun stake(user: &signer, amount: u64) {
        let aptos_coin = coin::withdraw<AptosCoin>(user, amount); // withdraw AptosCoin from the signer account
        coin::deposit(@resource_account, aptos_coin); // deposit AptosCoin to the resource account
    }

    public entry fun unstake(user: &signer, amount: u64) acquires ModuleData {
        let module_data = borrow_global_mut<ModuleData>(@resource_account);
        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);

        let aptos_coin = coin::withdraw<AptosCoin>(&resource_signer, amount);
        coin::deposit(signer::address_of(user), aptos_coin);
    }

}