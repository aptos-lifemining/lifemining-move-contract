// Implement stake / unstake functions here
// TODO: additional sercurity works
module vault_account::VaultWithSimpleMap {
    use std::error;
    use std::signer;
    use aptos_std::simple_map::{Self, SimpleMap};
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
        vault_ledger: SimpleMap<address, u64> // <LifeMining participant's address, staked amount>
    }

    fun init_module(vault_signer: &signer) {
        let vault_signer_cap = resource_account::retrieve_resource_account_cap(vault_signer, @source_addr);

        move_to(vault_signer, ModuleData{
            signer_cap: vault_signer_cap,
        });

        move_to(vault_signer, VaultLedger {
            vault_ledger: simple_map::create(),
        });

        coin::register<AptosCoin>(vault_signer);
    }    
}