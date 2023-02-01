// Implement stake / unstake functions here
// TODO: additional sercurity works
module vault_account::LifeMiningVault {
    use std::error;
    use std::signer;
    use aptos_std::table::{Self, Table};
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::coin;
    use aptos_framework::resource_account;
    use aptos_framework::aptos_coin::{AptosCoin};

    const EINSUFFICIENT_STAKED_AMOUNT_IN_VAULT: u64 = 0;

    // TODO: Access control for the signer capability.
    struct ModuleData has key {
        signer_cap: SignerCapability,
    }

    struct VaultLedger has key {
        vault_ledger: Table<address, u64> // <LifeMining participant's address, staked amount>
    }

    fun init_module(vault_signer: &signer) {
        let vault_signer_cap = resource_account::retrieve_resource_account_cap(vault_signer, @source_addr);

        move_to(vault_signer, ModuleData{
            signer_cap: vault_signer_cap,
        });

        move_to(vault_signer, VaultLedger {
            vault_ledger: table::new(),
        });

        coin::register<AptosCoin>(vault_signer);
    }

    // get staked amount data from the vault_ledger table
    public entry fun get_staked_amount(user: &signer) acquires VaultLedger {
        let ledger_table = borrow_global_mut<VaultLedger>(@vault_account);
        let staked_amount = table::borrow_mut_with_default(&mut ledger_table.vault_ledger, signer::address_of(user), 0); // Acquire a mutable reference to the vault ledger table value corresponds to the user address.
        *staked_amount;
    }

    public entry fun stake_to_vault(user: &signer, amount: u64) acquires VaultLedger {
        let aptos_coin = coin::withdraw<AptosCoin>(user, amount); // withdraw AptosCoin from the signer account
        coin::deposit(@vault_account, aptos_coin); // deposit AptosCoin to the resource account
        
        let ledger_table = borrow_global_mut<VaultLedger>(@vault_account);
        let staked_amount = table::borrow_mut_with_default(&mut ledger_table.vault_ledger, signer::address_of(user), 0); // Acquire a mutable reference to the vault ledger table value corresponds to the user address.
        *staked_amount = *staked_amount + amount; // add staked amount to the ledger.
    }

    public entry fun unstake_from_vault(user: &signer, amount: u64) acquires ModuleData, VaultLedger {

        let ledger_table = borrow_global_mut<VaultLedger>(@vault_account);
        let staked_amount = table::borrow_mut_with_default(&mut ledger_table.vault_ledger, signer::address_of(user), 0); // Acquire a mutable reference to the vault ledger table value corresponds to the user address.

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