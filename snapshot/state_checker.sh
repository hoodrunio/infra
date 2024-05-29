#!/bin/bash

name=$1
rpc_address=$2
daemon=$3
config_dir=$4
base_dir=$5

while true; do
    catching_up=$(curl -s "${rpc_address}/status" | jq -r .result.sync_info.catching_up)
    if [ "$catching_up" == "false" ]; then
        echo "Chain $name has synchronized. Exiting state-sync mode."

        # Stop the node
        sudo systemctl stop $daemon

        # Disable state-sync configuration
        sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false| ; \
        s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"\"| ; \
        s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\10| ; \
        s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"\"|" "$config_dir"

        # Start the node
        sudo systemctl start $daemon

        echo "Chain $name has returned to normal mode and is ready for snapshotting."
        break
    else
        echo "Chain $name has not synchronized yet. Waiting..."
        sleep 60
    fi
done
