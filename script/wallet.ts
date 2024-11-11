import { createWalletClient, http } from 'viem'
import { mekong } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { eip7702Actions } from 'viem/experimental'
 
export const walletClient = createWalletClient({
  account: privateKeyToAccount("0xPRIVATE_KEY"),
  chain: mekong,            // Devcon testnet
  transport: http(),
}).extend(eip7702Actions())

// Based on https://viem.sh/experimental/eip7702/contract-writes