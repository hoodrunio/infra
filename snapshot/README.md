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
    }
]
```
### Example Overview

![image](https://github.com/hoodrunio/infra/assets/71728280/0538d9d8-7ba2-4847-a73e-f17e2f0a23c5)
