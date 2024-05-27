# Cosmos SDK-Based Chain Port Management Script

This script is designed to manage ports and configurations for multiple Cosmos SDK-based chains. It ensures that there are no port conflicts by dynamically assigning available ports within specified ranges.

## Features

- **Collect Used Ports:** Gathers currently used ports and stores them in a file.
- **Check Port Availability:** Ensures that a port is available before assigning it.
- **Retrieve Next Available Port:** Finds the next available port within defined ranges.
- **Update JSON File:** Stores the new chain ports in the JSON file.
- **Modify Configuration Files:** Updates the chain's configuration files with the new port assignments.

## Usage

1. **Make the Script Executable:**
```bash
chmod +x port.sh
```
1. **Run the Script:**
```sh
./port.sh "chain_name:/path/to/custom/config"
```
- `chain_name`: The name of the chain you want to configure.
- `/path/to/custom/config`: (Optional) Custom path to the chain's configuration directory. If not provided, the default path `($HOME/{.chain_name}d/config)` will be used.
