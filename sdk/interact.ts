// Copyright (c) Aptos
// SPDX-License-Identifier: Apache-2.0

/* eslint-disable no-console */

import dotenv from "dotenv";
dotenv.config();

import {
  AptosClient,
  AptosAccount,
  FaucetClient,
  TokenClient,
  CoinClient,
} from "aptos";

export const NODE_URL = "https://fullnode.testnet.aptoslabs.com";
export const FAUCET_URL = "https://faucet.testnet.aptoslabs.com";

(async () => {
  // Create API and faucet clients.
  // :!:>section_1a
  const client = new AptosClient(NODE_URL);
  const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL); // <:!:section_1a

  // Create client for working with the token module.
  // :!:>section_1b
  const tokenClient = new TokenClient(client); // <:!:section_1b

  // Create a coin client for checking account balances.
  const coinClient = new CoinClient(client);

  // Resource Account that created the collection

  const resourceAccount =
    "aef92afd9bcce9a48a66ec4088b19624ebb5b3658e3d5669b3fa58412edec093";

  // Create accounts.
  // :!:>section_2
  const alice = new AptosAccount(
    new Uint8Array(
      Buffer.from(
        "0x7753c89004c370efefe2ce69a725f64056a3077aaa48afc387a6733656cffa38"
      )
    ),
    "0x470ea80201980ec4f5fa86239a14e4ce36c73f502908edd81292e57da4a77359"
  );

  const collectionName = `LifeMining Profile Collection V1`;
  const tokenName = `LMProfileV1: 0x000001's Profile`;
  console.log(tokenName);
  //   const bob = new AptosAccount(); // <:!:section_2

  //   // Print out account addresses.
  //   console.log("=== Addresses ===");
  //   console.log(`Alice: ${alice.address()}`);
  //   console.log(`Bob: ${bob.address()}`);
  //   console.log("");

  //   // Fund accounts.
  //   // :!:>section_3
  //   await faucetClient.fundAccount(alice.address(), 100_000_000);
  //   await faucetClient.fundAccount(bob.address(), 100_000_000); // <:!:section_3

  //   console.log("=== Initial Coin Balances ===");
  //   console.log(`Alice: ${await coinClient.checkBalance(alice)}`);
  //   console.log(`Bob: ${await coinClient.checkBalance(bob)}`);
  //   console.log("");

  //   console.log("=== Creating Collection and Token ===");

  //   const collectionName = "Alice's";
  //   const tokenName = "Alice's first token";
  //   const tokenPropertyVersion = 0;

  //   const tokenId = {
  //     token_data_id: {
  //       creator: alice.address().hex(),
  //       collection: collectionName,
  //       name: tokenName,
  //     },
  //     property_version: `${tokenPropertyVersion}`,
  //   };

  //   // Create the collection.
  //   // :!:>section_4
  //   const txnHash1 = await tokenClient.createCollection(
  //     alice,
  //     collectionName,
  //     "Alice's simple collection",
  //     "https://alice.com"
  //   ); // <:!:section_4
  //   await client.waitForTransaction(txnHash1, { checkSuccess: true });

  //   // Create a token in that collection.
  //   // :!:>section_5
  //   const txnHash2 = await tokenClient.createToken(
  //     alice,
  //     collectionName,
  //     tokenName,
  //     "Alice's simple token",
  //     1,
  //     "https://aptos.dev/img/nyan.jpeg"
  //   ); // <:!:section_5
  //   await client.waitForTransaction(txnHash2, { checkSuccess: true });

  // Print the collection data.
  // :!:>section_6
  //   try {
  //     const collectionData = await tokenClient.getCollectionData(
  //       alice.address(),
  //       collectionName
  //     );
  //     console.log(
  //       `Alice's collection: ${JSON.stringify(collectionData, null, 4)}`
  //     ); // <:!:section_6
  //   } catch (e) {
  //     console.log(e);
  //   }

  // Get the token balance.
  // :!:>section_7
  //   try {
  //     const aliceBalance1 = await tokenClient.getToken(
  //       alice.address(),
  //       collectionName,
  //       tokenName,
  //       `${0}`
  //     );
  //     console.log(`Alice's token balance: ${aliceBalance1["amount"]}`); // <:!:section_7
  //   } catch (e) {
  //     console.log(e);
  //   }

  // Get the token data.
  // :!:>section_8
  // try {
  //   // const tokenData = await tokenClient.getTokenData(
  //   //   alice.address(),
  //   //   collectionName,
  //   //   tokenName
  //   // );
  //   const tokenData = await tokenClient.getTokenData(
  //     resourceAccount,
  //     collectionName,
  //     tokenName
  //   );
  //   console.log(`Alice's token data: ${JSON.stringify(tokenData, null, 4)}`); // <:!:section_8
  // } catch (e) {
  //   console.log(">>>>>>>>>>> ERROR >>>>>>>>>>>>>>>");
  //   console.log(e);
  // }

  try {
    const collectionData = await tokenClient.getCollectionData(
      resourceAccount,
      collectionName
    );
    console.log(">>>>>>>> ========== CollectionData: \n", collectionData);
  } catch (e) {
    console.log(">>>>>>>>>> ERROR >>>>>>>>>>>>>>>>>");
    console.log(e);
  }

  try {
    const tokenData = await tokenClient.getTokenData(
      resourceAccount,
      collectionName,
      tokenName
    );
    console.log(
      `\n>>>>>>>> ========== tokenData: \n${JSON.stringify(tokenData, null, 4)}`
    );
  } catch (e) {
    console.log(">>>>>>>>>> ERROR >>>>>>>>>>>>>>>>>");
    console.log(e);
  }

  // try {
  //   const tokenId = {
  //     token_data_id: {
  //       creator: alice.address().hex(),
  //       collection: collectionName,
  //       name: tokenName,
  //     },
  //     property_version: `${0}`,
  //   };
  //   const aliceBalance = await tokenClient.getTokenForAccount(
  //     alice.address(),
  //     tokenId
  //   );
  //   console.log(">>>>>>>>>>>> Alice balance: ", aliceBalance);
  // } catch (e) {
  //   console.log(">>>>>>>>>>> ERROR >>>>>>>>>>>>");
  //   console.log(e);
  // }

  //   // Alice offers one token to Bob.
  //   console.log("\n=== Transferring the token to Bob ===");
  //   // :!:>section_9
  //   const txnHash3 = await tokenClient.offerToken(
  //     alice,
  //     bob.address(),
  //     alice.address(),
  //     collectionName,
  //     tokenName,
  //     1,
  //     tokenPropertyVersion
  //   ); // <:!:section_9
  //   await client.waitForTransaction(txnHash3, { checkSuccess: true });

  //   // Bob claims the token Alice offered him.
  //   // :!:>section_10
  //   const txnHash4 = await tokenClient.claimToken(
  //     bob,
  //     alice.address(),
  //     alice.address(),
  //     collectionName,
  //     tokenName,
  //     tokenPropertyVersion
  //   ); // <:!:section_10
  //   await client.waitForTransaction(txnHash4, { checkSuccess: true });

  //   // Print their balances.
  //   const aliceBalance2 = await tokenClient.getToken(
  //     alice.address(),
  //     collectionName,
  //     tokenName,
  //     `${tokenPropertyVersion}`
  //   );
  //   const bobBalance2 = await tokenClient.getTokenForAccount(
  //     bob.address(),
  //     tokenId
  //   );
  //   console.log(`Alice's token balance: ${aliceBalance2["amount"]}`);
  //   console.log(`Bob's token balance: ${bobBalance2["amount"]}`);

  //   console.log(
  //     "\n=== Transferring the token back to Alice using MultiAgent ==="
  //   );
  //   // :!:>section_11
  //   let txnHash5 = await tokenClient.directTransferToken(
  //     bob,
  //     alice,
  //     alice.address(),
  //     collectionName,
  //     tokenName,
  //     1,
  //     tokenPropertyVersion
  //   ); // <:!:section_11
  //   await client.waitForTransaction(txnHash5, { checkSuccess: true });

  //   // Print out their balances one last time.
  //   const aliceBalance3 = await tokenClient.getToken(
  //     alice.address(),
  //     collectionName,
  //     tokenName,
  //     `${tokenPropertyVersion}`
  //   );
  //   const bobBalance3 = await tokenClient.getTokenForAccount(
  //     bob.address(),
  //     tokenId
  //   );
  //   console.log(`Alice's token balance: ${aliceBalance3["amount"]}`);
  //   console.log(`Bob's token balance: ${bobBalance3["amount"]}`);
})();
