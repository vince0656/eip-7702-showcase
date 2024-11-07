# EIP 7702 Showcase

Taking EIP7702 for a spin on devnet launched for Devcon 7 SEA

## Smart Contracts
The smart contracts be found in [`smart-contracts`](./smart-contracts/) which use the foundry framework

Due to the use of `transient` storage, you may be required to use the following build command:
```
FOUNDRY_EVM_VERSION=cancun forge build
```