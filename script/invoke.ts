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