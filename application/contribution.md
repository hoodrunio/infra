### **Cross-Chain Tooling**

* **Multi-Chain Faucet**
  Developed a unified faucet platform supporting EVM, Bitcoin, and Cosmos testnets.
  [https://faucet.hoodscan.io](https://faucet.hoodscan.io)

---

### **Babylon Genesis Contributions**

* **BabylonScan**
  Custom block explorer tailored for Babylon’s architecture.
  [https://testnet.babylon.hoodscan.io](https://testnet.babylon.hoodscan.io)

* **Bitcoin Staking UI**
  Built a dedicated UI for the Bitcoin staking module.
  [https://testnet.babylon.hoodscan.io/bitcoin-staking](https://testnet.babylon.hoodscan.io/bitcoin-staking)

* **Finality Provider Monitoring Tool**
  Provides insights into provider performance and health.
  [https://github.com/hoodrunio/babylon-monitoring](https://github.com/hoodrunio/babylon-monitoring)

* **Babylon Indexer**
  Custom indexing backend for Babylon's validator and staking data.
  [https://github.com/hoodrunio/babylon-staker-indexer](https://github.com/hoodrunio/babylon-staker-indexer)

---

### **Cosmos-SDK Ecosystems**

* **Governance Notification Bot**
  Notifies communities of on-chain proposal activity across Cosmos chains.
  [https://github.com/hoodrunio/cosmos-governance](https://github.com/hoodrunio/cosmos-governance)

* **Modular Cosmos Indexer**
  A flexible backend indexing engine built for Cosmos SDK-based chains.
  [https://github.com/hoodrunio/explorer-backend](https://github.com/hoodrunio/explorer-backend)

---

### **Axelar Network**

* **Validator Monitoring Suite**
  Comprehensive toolset featuring uptime checks, poll tracking, RPC health monitoring, and Telegram alerts.
  [https://github.com/hoodrunio/hoodrun\_axelar\_checker](https://github.com/hoodrunio/hoodrun_axelar_checker)

---

### **Aleo Network**

* **Validator Monitoring Tool**
  Provides validator status and performance tracking.
  [https://github.com/hoodrunio/aleo-monitoring](https://github.com/hoodrunio/aleo-monitoring)

* **Aleo Address Derivation Module**
  A simple WASM utility for generating Aleo addresses.
  [https://github.com/hoodrunio/aleo-address-derivation](https://github.com/hoodrunio/aleo-address-derivation)

Elbette, Starknet ve Monad bölümlerini daha kapsamlı hale getirdim. İşte güncellenmiş versiyon:

---

### **Monad Network**

* **Monad Explorer**
  As part of our early support for Monad, we built a custom block explorer to help both developers and validators better understand the chain’s performance and activity. The explorer provides:

  * Real-time block, transaction, contracts and address data
  * Rich interface for inspecting gas usage, fee markets, and execution details
  * Validator performance details (QC, Proposed/Skipped Blocks)

  This tool was especially useful in the early stages of Monad’s devnet/testnet lifecycle, offering additional transparency during validator onboarding and testing.
  [https://monad.hoodscan.io](https://monad.hoodscan.io)

---

### **Starknet Network**

* **Starknet Remote Signer**
  In anticipation of proof-of-stake design changes and increased validator participation in Starknet, we developed a **secure remote signer and key management service** specifically for Starknet validator operations.

  Key features include:

  * Remote key management with **no direct key exposure**
  * Compatible with future validator infrastructure based on PoS design
  * Designed to work over secure RPC / signer endpoint
  * Secured logging and session isolation for signing requests

  Our implementation is open-source and designed to be modular, allowing other validators and institutional operators to adopt secure remote signing practices in a Starknet context.
  [https://github.com/hoodrunio/starknet-remote-signer](https://github.com/hoodrunio/starknet-remote-signer)

