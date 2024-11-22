# EIP 7702 Showcase

Taking EIP7702 for a spin on devnet launched for Devcon 7 SEA: `Mekong`.

The project consists of very primitive Solidity smart contracts as well as a `viem` based script that abstracts away the EIP-7702 complexities associated with the new transaction type.

## Smart Contracts
The smart contracts be found in [`smart-contracts`](./smart-contracts/) which use the foundry framework

Due to the use of `transient` storage, you may be required to use the following build command:
```
FOUNDRY_EVM_VERSION=cancun forge build
```

or alternatively:
```
forge build --evm-version cancun
```

## Example 1: Pre and Post Transaction checks

These smart contracts allow selective transaction execution where organisational rules are encoded to be checked before a set of transactions and then after. 

## Example 2: No ETH account

A way for operational transactions to be executed by an authorized EOA with the gas paid by a known treasury, refunding any change back to the treasury.

This is different to the concept of a GAS station network because we are not aiming for a protocol paying for a user's transactions (which comes with complex infra). It is more likely that such a solution
would be used witin a single organisation where perhaps a development team are attempting to deploy a smart contract or exeucte operations and an organisation does not want
to concern itself with distributing ETH to various wallets for that purpose and then have to deal with ensuring the funds are returned afterwards. EIP7702 using the smart contracts
in Example 2 simplifies this situation by keeping the treasury and operational EOAs seperate. It ensures that any EOA authorised to use the treasury for transactions will not
be left with any ETH that they later need to keep track of and the authorisation is only valid for one transaction ensuring the door is not left open for abuse.

## Viem script

The main script for executing a smart contract from an EOA is [`invoke.ts`](./script/invoke.ts):
```typescript
import { parseEther } from 'viem'
import { walletClient } from './wallet'
import { abi, contractAddress } from './contract'
 
async function main() {
  // 1. Authorize injection of the Contract's bytecode into the Account created from `wallet.ts`.
  const authorization = await walletClient.signAuthorization({
    contractAddress,
  })
   
  // 2. Invoke the Contract's `executeBatchTransactions` function to perform batch calls.
  const hash = await walletClient.writeContract({
    abi,
    address: walletClient.account.address,
    functionName: 'executeBatchTransactions',
    args: [[
      {
        callData: '0x',
        target: '0xcb98643b8786950F0461f3B0edf99D88F274574D', 
        value: parseEther('0.001'), 
      }, {
        callData: '0x',
        target: '0xd2135CfB216b74109775236E36d4b433F1DF507B', 
        value: parseEther('0.002'), 
      }
    ]],
    authorizationList: [authorization],
    //                  ↑ 3. Pass the Authorization as an option which allows anyone to actually execute the transaction. tx.origin does not need to be the EOA that authorized
  })

  console.log('Transaction: ', hash);
}

main();

// Based on: https://viem.sh/experimental/eip7702/contract-writes
```