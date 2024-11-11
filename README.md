# EIP 7702 Showcase

Taking EIP7702 for a spin on devnet launched for Devcon 7 SEA: `Mekong`.

The project consists of very primitive Solidity smart contracts as well as a `viem` based script that abstracts away the EIP-7702 complexities associated with the new transaction type.

## Smart Contracts
The smart contracts be found in [`smart-contracts`](./smart-contracts/) which use the foundry framework

Due to the use of `transient` storage, you may be required to use the following build command:
```
FOUNDRY_EVM_VERSION=cancun forge build
```

## Viem script

The main script is [`invoke.ts`](./script/invoke.ts):
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