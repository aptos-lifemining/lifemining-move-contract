// Implement stake / unstake functions here
// TODO: additional sercurity works
module test_account::StakingTest {
    use std::error;
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};

    const EINSUFFICIENT_STAKED_AMOUNT_IN_VAULT: u64 = 0;

    // TODO: Access control for the signer capability.
    struct ModuleData has key {
        signer_cap: SignerCapability,
    }

    struct VaultLedger has key {
        vault_ledger: SimpleMap<address, u64> // <LifeMining participant's address, staked amount>
    }

    fun init_module() {
        // let vault_signer_cap = resource_account::retrieve_resource_account_cap(test_signer, @source_addr);

        // move_to(test_signer, ModuleData{
        //     signer_cap: vault_signer_cap,
        // });

        // move_to(test_signer, VaultLedger {
        //     vault_ledger: simple_map::create(),
        // });

        // coin::register<AptosCoin>(vault_signer);
    }

    public entry fun stake_to_vault(user: &signer, amount: u64) acquires VaultLedger {
        let aptos_coin = coin::withdraw<AptosCoin>(user, amount); // withdraw AptosCoin from the signer account
        coin::deposit(@vault_account, aptos_coin); // deposit AptosCoin to the resource account
        
        let ledger_table = borrow_global_mut<VaultLedger>(@vault_account);

        // create a new entry in the vault ledger table if the user is not in the table.
        if (!simple_map::contains_key(&ledger_table.vault_ledger, &signer::address_of(user))) {
            simple_map::add(&mut ledger_table.vault_ledger, signer::address_of(user), 0);
        };

        let staked_amount = simple_map::borrow_mut(&mut ledger_table.vault_ledger, &signer::address_of(user)); // Acquire a mutable reference to the vault ledger table value corresponds to the user address.
        *staked_amount = *staked_amount + amount; // add staked amount to the ledger.
    }

    public entry fun unstake_from_vault(user: &signer, amount: u64) acquires ModuleData, VaultLedger {

        let ledger_table = borrow_global_mut<VaultLedger>(@vault_account);
        
        // create a new entry in the vault ledger table if the user is not in the table.
        if (!simple_map::contains_key(&ledger_table.vault_ledger, &signer::address_of(user))) {
            simple_map::add(&mut ledger_table.vault_ledger, signer::address_of(user), 0);
        };

        let staked_amount = simple_map::borrow_mut(&mut ledger_table.vault_ledger, &signer::address_of(user)); // Acquire a mutable reference to the vault ledger table value corresponds to the user address.

        // Only allow unstaking if the user has enough amount of coin in the vault ledger.
        assert!(
            *staked_amount >= amount,
            error::aborted(EINSUFFICIENT_STAKED_AMOUNT_IN_VAULT)
        );

        let module_data = borrow_global_mut<ModuleData>(@vault_account);
        let vault_signer = account::create_signer_with_capability(&module_data.signer_cap);

        let aptos_coin = coin::withdraw<AptosCoin>(&vault_signer, amount);
        coin::deposit(signer::address_of(user), aptos_coin);

        *staked_amount = *staked_amount - amount; // discount staked amount of the user from the vault ledger.
    }

    
}