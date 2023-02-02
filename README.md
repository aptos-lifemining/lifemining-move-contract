# lifemining-move-contract

Move modules for `LifeMining service`

__(Project from Aptos Seoul Hackathon 2023)__

## Deploy on Resource Account (Aptos CLI)
```
$ aptos move create-resource-account-and-publish-package --seed [__seed_phrase__]  \
--address-name challenge_admin_resource_account --profile [__deploy_account__] \
--named-addresses source_addr=[__deploy_account__]
```

## LifeMining Move Resources
<img width="3332" alt="LifeMining Move Resource Relationship" src="https://user-images.githubusercontent.com/91793849/216420283-a1546501-4562-4a33-a8d5-ca0344a36304.png">
<img width="3332" alt="LifeMining Move Account Responsibilities" src="https://user-images.githubusercontent.com/91793849/216420287-e565e53c-095d-4ee2-96ed-39731b5cc831.png">

![화면1](https://user-images.githubusercontent.com/91793849/216461073-bd02783a-89aa-4cf7-8238-dddfed84a4f0.png)
![화면2](https://user-images.githubusercontent.com/91793849/216461092-ac612791-6dee-404f-863c-a725f680fac5.png)
![화면3](https://user-images.githubusercontent.com/91793849/216461098-d65c388f-2749-4f4a-90aa-63492e17309b.png)
