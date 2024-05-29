# Snapshot Script for Cosmos SDK-based Chains

This script automates the process of taking snapshots of Cosmos SDK-based blockchain data directories. It stops the daemon, takes a snapshot, compresses it, and restarts the daemon. The script uses `zstd` for compression and allows for easy integration with multiple chains by specifying chain information as input parameters or via a JSON file for automation.

## Features
- Stops the daemon before taking a snapshot to ensure data consistency.
- Takes a snapshot and compresses it using `zstd`.
- Restarts the daemon after the snapshot is taken.
- Provides clear and colorful output for better readability.
- Supports multiple chains through input parameters.
- Differentiates between mainnet and testnet, storing snapshots in separate directories.
- Automates the snapshot process using a JSON file and crontab.

## Prerequisites
- Ensure you have `curl`, `jq`, `pv`, and `zstd` installed on your system.
- Ensure the script has execute permissions: `chmod +x snapshot_script.sh`.

## Usage

### Input Format
The script accepts chain information as input in the following format:

### Example Commands
#### Terminal Command
Run the script for a single chain:

```bash
./snapshot_script.sh "axelar|http://localhost:11117|/home/axelar/.axelar/data|mainnet"
```
or with a custom daemon name:
```bash
./snapshot_script.sh "celestia|http://localhost:26657|/home/celestia/.celestia/data|testnet|celestia-appd"
```
#### JSON file command (Recommended for Automation)
Run the script for multiple chains using the JSON file:
```bash
/root/snapshot_script.sh /path/to/chains.json
```
### Example JSON 
```json
[
    {
        "chain": "axelar",
        "rpc_address": "http://localhost:11117",
        "data_dir": "/home/axelar/.axelar/data",
        "network_type": "mainnet"
    },
    {
        "chain": "cosmos",
        "rpc_address": "http://localhost:26657",
        "data_dir": "/home/cosmos/.gaiad/data",
        "network_type": "testnet"
    },
    {
        "chain": "celestia",
        "rpc_address": "http://localhost:26680",
        "data_dir": "/home/celestia/.celestia/data",
        "network_type": "mainnet",
        "daemon": "celestia-appd"
    }
]
```
### Example Overview

![image](https://github.com/hoodrunio/infra/assets/71728280/0538d9d8-7ba2-4847-a73e-f17e2f0a23c5)

# State-Sync Scripts

## Init state-sync 

This script is used to initiate the state-sync process when the data size of a chain exceeds a specified limit. This script updates the chain's configuration file, fetches necessary state-sync information, cleans the data directory, and starts the state-sync process.

```bash
chmod +x state_sync_start.sh
./state_sync_start.sh
```
## Configuration
This script requires a JSON file containing the chain information. Below is an example format of the JSON file:

```json
{
  "chains": [
    {
      "name": "evmos",
      "base_dir": "$HOME/.evmosd",
      "daemon": "evmosd",
      "max_size_gb": 100,
      "state_sync_supported": true,
      "state_sync_rpc_servers": "http://localhost:26657,http://localhost:26658",
      "wasm_supported": false
    },
    {
      "name": "axelar",
      "base_dir": "$HOME/.axelar",
      "daemon": "axelard",
      "max_size_gb": 50,
      "state_sync_supported": true,
      "state_sync_rpc_servers": "http://localhost:26657,http://localhost:26658",
      "wasm_supported": true
    },
    {
      "name": "celestia",
      "base_dir": "$HOME/.celestia-app",
      "daemon": "celestia-appd",
      "max_size_gb": 1,
      "state_sync_supported": true,
      "state_sync_rpc_servers": "http://localhost:26657,http://localhost:26658",
      "wasm_supported": false
    }
  ]
}
```

## Check State-sync status
### Description
`state_sync_check.sh` checks the synchronization status after initiating the state-sync process. Once the synchronization is complete, it switches the chain back to normal mode and disables the state-sync configuration.

### Usage
This script is automatically called by `state_sync_start.sh` and runs in the background. Manual execution is not required.

## Scenario
When `state_sync_start.sh` is executed:

- The script checks the data size of the chain.
- If the data size exceeds the specified limit, the state-sync process is initiated.
- `state_sync_check.sh` is called in the background to monitor the synchronization status.
- Once synchronization is complete, the chain is switched back to normal mode and snapshot operations continue.
