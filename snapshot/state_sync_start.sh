#!/bin/bash

CONFIG_FILE="$HOME/chains_config.json"
DEFAULT_MAX_SIZE_GB=3

# Read the JSON file and parse the chain information
chains=$(jq -c '.chains[]' "$CONFIG_FILE")

for chain in $chains; do
    name=$(echo "$chain" | jq -r '.name')
    base_dir=$(eval echo "$(echo "$chain" | jq -r '.base_dir')")
    daemon=$(echo "$chain" | jq -r '.daemon')
    max_size_gb=$(echo "$chain" | jq -r '.max_size_gb')
    state_sync_supported=$(echo "$chain" | jq -r '.state_sync_supported')
    state_sync_rpc_servers=$(echo "$chain" | jq -r '.state_sync_rpc_servers')
    first_rpc_server=$(echo "$state_sync_rpc_servers" | cut -d ',' -f 1)
    wasm_supported=$(echo "$chain" | jq -r '.wasm_supported')

    data_dir="${base_dir}/data"
    config_dir="${base_dir}/config/config.toml"

    if [ "$max_size_gb" == "null" ]; then
        max_size_gb=$DEFAULT_MAX_SIZE_GB
    fi

    # Check the current size of the data directory
    if [ -d "$data_dir" ]; then
        current_size_gb=$(du -sh "$data_dir" | awk '{print $1}' | sed 's/G//')
    else
        echo "Directory $data_dir not found, skipping size check."
        continue
    fi

    if (( $(echo "$current_size_gb > $max_size_gb" | bc -l) )); then
        if [ "$state_sync_supported" == "true" ]; then
            echo "Starting state-sync for chain $name. Current size: ${current_size_gb}GB, Maximum size: ${max_size_gb}GB"

            # Commands for state-sync process
            latest_block_height=$(curl -s "${first_rpc_server}/block" | jq -r .result.block.header.height)
            if [ "$latest_block_height" == "null" ] || [ -z "$latest_block_height" ]; then
                echo "Failed to retrieve latest_block_height, skipping chain $name."
                continue
            fi

            state_sync_trust_height=$((latest_block_height - 2000))
            state_sync_trust_hash=$(curl -s "${first_rpc_server}/block?height=${state_sync_trust_height}" | jq -r .result.block_id.hash)
            if [ "$state_sync_trust_hash" == "null" ] || [ -z "$state_sync_trust_hash" ]; then
                echo "Failed to retrieve state_sync_trust_hash, skipping chain $name."
                continue
            fi

            # Stop the node
            sudo systemctl stop "$daemon"

            # Add state-sync configuration
            sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
            s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$state_sync_rpc_servers\"| ; \
            s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$state_sync_trust_height| ; \
            s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$state_sync_trust_hash\"|" "$config_dir"

            # Clean the data directory
            if "$daemon" unsafe-reset-all --home "$base_dir" --keep-addr-book; then
                echo "$daemon unsafe-reset-all command succeeded"
            elif "$daemon" tendermint unsafe-reset-all --home "$base_dir" --keep-addr-book; then
                echo "$daemon tendermint unsafe-reset-all command succeeded"
            else
                echo "$daemon reset commands failed" >&2
                exit 1
            }

            # Check and download wasm directory if necessary
            if [ "$wasm_supported" == "true" ]; then
                if [ -d "$data_dir/wasm" ]; then
                    echo "wasm directory exists, will be preserved"
                else
                    echo "wasm directory not found, downloading"
                    wget -O wasm.tar.lz4 https://snapshot_url/wasm.tar.lz4 --inet4-only
                    lz4 -c -d wasm.tar.lz4 | tar -x -C "$data_dir"
                    rm wasm.tar.lz4
                fi
            else
                echo "Chain $name does not support wasm."
            fi

            # Start the node
            sudo systemctl start "$daemon"

            echo "State-sync process started for chain $name."

            # Run the synchronization check script in the background
            /path/to/state_sync_check.sh "$name" "$first_rpc_server" "$daemon" "$config_dir" "$base_dir" &
        else
            echo "Chain $name does not support state-sync. Checking size."
        fi
    else
        echo "Size limit not exceeded for chain $name. Current size: ${current_size_gb}GB, Maximum size: ${max_size_gb}GB"
    fi
done
