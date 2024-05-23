#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Server configurations
CHAIN_NAMES=("evmos" "axelar") # Add all your chain names here
DAEMON_PREFIX="d"
SNAPSHOT_URL_BASE="http://<Server_1_IP>/snapshots"

# Configurations for chains with special data directories
declare -A SPECIAL_CHAIN_DATA_DIRS=(
    ["axelar"]="$HOME/.axelar/data"
    # Specify other chains and their special data directories here
)

# Disk usage threshold (percentage)
DISK_USAGE_THRESHOLD=80

# Function to check disk usage
check_disk_usage() {
    local usage=$(df -h / | grep -vE '^Filesystem' | awk '{ print $5 }' | sed 's/%//g')
    echo $usage
}

# State Sync configuration function
configure_state_sync() {
    local chain=$1
    local rpc_server=$2
    local latest_height=$(curl -s $rpc_server/status | jq -r .result.sync_info.latest_block_height)
    local trust_height=$((latest_height - 2000))
    local trust_hash=$(curl -s "$rpc_server/block?height=$trust_height" | jq -r .result.block_id.hash)

    if [ -z "$trust_height" ] || [ -z "$trust_hash" ]; then
        echo -e "${RED}Failed to get trust height or trust hash, skipping chain $chain.${NC}"
        return 1
    fi

    local config="
[statesync]
enable = true
rpc-servers = [\"$rpc_server\"]
trust-height = $trust_height
trust-hash = \"$trust_hash\"
"

    echo "$config" > "$HOME/.${chain}d/config/config.toml"
    return 0
}

# Function to resync using a snapshot
resync_from_snapshot() {
    local chain=$1
    local daemon=$2
    local data_dir=$3
    local snapshot_url="${SNAPSHOT_URL_BASE}/${chain}/latest.tar.zst"

    wget -O /tmp/${chain}_snapshot.tar.zst $snapshot_url
    mkdir -p $data_dir
    tar -I zstd -xvf /tmp/${chain}_snapshot.tar.zst -C $data_dir

    sudo systemctl stop $daemon
    $daemon unsafe-reset-all --home $(dirname "$data_dir") --keep-addr-book
    sudo systemctl start $daemon
}

# Main processing loop
for chain in "${CHAIN_NAMES[@]}"; do
    daemon="${chain}${DAEMON_PREFIX}"
    data_dir="$HOME/.${chain}d/data"

    if [[ -v SPECIAL_CHAIN_DATA_DIRS[$chain] ]]; then
        data_dir=${SPECIAL_CHAIN_DATA_DIRS[$chain]}
    fi

    if ! systemctl is-active --quiet $daemon; then
        echo -e "${RED}Daemon $daemon is not running, skipping chain $chain.${NC}"
        continue
    fi

    rpc_server="http://localhost:26657" # Specify the RPC server address here
    configure_state_sync $chain $rpc_server
    if [ $? -ne 0 ]; then
        continue
    fi

    disk_usage=$(check_disk_usage)
    if [ $disk_usage -ge $DISK_USAGE_THRESHOLD ]; then
        echo -e "${YELLOW}Disk usage is $disk_usage%, resyncing: Chain = $chain${NC}"
        resync_from_snapshot $chain $daemon $data_dir
        echo -e "${CYAN}Resync completed: Chain = $chain${NC}"
    else
        echo -e "${GREEN}Disk usage is $disk_usage%, continuing in state-sync mode: Chain = $chain${NC}"
    fi
done
