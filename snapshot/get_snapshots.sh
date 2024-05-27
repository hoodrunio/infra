#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

BOLD=$(tput bold)
NORMAL=$(tput sgr0)

DAEMON_PREFIX="d"
SNAPSHOT_BASE_DIR="/var/www/snapshots"

# Get the total number of cores and calculate 70% of it
TOTAL_CORES=$(nproc)
ZSTD_CORES=$(awk -v cores="$TOTAL_CORES" 'BEGIN { printf "%d\n", cores * 0.7 }')

process_chain() {
    CHAIN=$1
    RPC_ADDRESS=$2
    DATA_DIR=$3
    NETWORK_TYPE=$4

    # Check if the data directory is custom
    if [[ "$DATA_DIR" == /* ]]; then
        DATA_DIR=$(eval echo "$DATA_DIR")
    else
        DATA_DIR="$HOME/.${CHAIN}d/data"
    fi

    DAEMON="${CHAIN}${DAEMON_PREFIX}"
    SNAPSHOT_DIR="${SNAPSHOT_BASE_DIR}/${NETWORK_TYPE}/${CHAIN}"

    echo -e "${BOLD}${MAGENTA}=============================="
    echo -e " Starting Process: ${CHAIN} (${NETWORK_TYPE})"
    echo -e "==============================${NC}"

    echo -e "${CYAN}Chain: ${YELLOW}${CHAIN}${NC}"
    echo -e "${CYAN}RPC Address: ${YELLOW}${RPC_ADDRESS}${NC}"
    echo -e "${CYAN}Data Directory: ${YELLOW}${DATA_DIR}${NC}"
    echo -e "${CYAN}Network Type: ${YELLOW}${NETWORK_TYPE}${NC}"

    if ! systemctl is-active --quiet "$DAEMON"; then
        echo -e "${RED}Daemon $DAEMON is not running, skipping chain $CHAIN.${NC}"
        return
    fi

    # Check the output of `curl` and `jq` commands
    CURL_OUTPUT=$(curl -s "${RPC_ADDRESS}/status")
    BLOCK_HEIGHT=$(echo "$CURL_OUTPUT" | jq -r .result.sync_info.latest_block_height)
    
    echo -e "${CYAN}Curl Output: ${NC}${CURL_OUTPUT}"
    echo -e "${CYAN}Block Height: ${YELLOW}${BLOCK_HEIGHT}${NC}"

    if [ -z "$BLOCK_HEIGHT" ] || [ "$BLOCK_HEIGHT" == "null" ]; then
        echo -e "${RED}Block height could not be retrieved, skipping chain $CHAIN.${NC}"
        return
    fi

    echo -e "${GREEN}Taking snapshot: Chain = ${CHAIN}, Block Height = ${BLOCK_HEIGHT}${NC}"

    if [ ! -d "$SNAPSHOT_DIR" ]; then
        mkdir -p "$SNAPSHOT_DIR"
    fi

    sudo systemctl stop "$DAEMON"
    rm -f "$SNAPSHOT_DIR"/*.tar.zst

    SNAPSHOT_FILENAME="${CHAIN}_height_${BLOCK_HEIGHT}.tar.zst"
    echo -e "${YELLOW}Snapshot file name: ${SNAPSHOT_FILENAME}${NC}"

    stdbuf -oL tar -cf - -C "$DATA_DIR" . | pv -terb -s $(du -sb "$DATA_DIR" | awk '{print $1}') | stdbuf -oL zstd -T"$ZSTD_CORES" -o "$SNAPSHOT_DIR/$SNAPSHOT_FILENAME"

    sudo systemctl start "$DAEMON"

    echo -e "${CYAN}Snapshot completed: ${SNAPSHOT_FILENAME}${NC}"
    echo -e "${BOLD}${MAGENTA}=============================="
    echo -e " Process Completed: ${CHAIN} (${NETWORK_TYPE})"
    echo -e "==============================${NC}"
}

# Check if input is a JSON file
if [[ "$1" == *.json ]]; then
    CHAINS=$(jq -c '.[]' "$1")
    for CHAIN_INFO in $CHAINS; do
        CHAIN=$(echo "$CHAIN_INFO" | jq -r '.chain')
        RPC_ADDRESS=$(echo "$CHAIN_INFO" | jq -r '.rpc_address')
        DATA_DIR=$(echo "$CHAIN_INFO" | jq -r '.data_dir')
        NETWORK_TYPE=$(echo "$CHAIN_INFO" | jq -r '.network_type')
        process_chain "$CHAIN" "$RPC_ADDRESS" "$DATA_DIR" "$NETWORK_TYPE"
    done
else
    # Read and parse parameters
    for CHAIN_INFO in "$@"; do
        IFS='|' read -r CHAIN RPC_ADDRESS DATA_DIR NETWORK_TYPE <<< "$CHAIN_INFO"
        process_chain "$CHAIN" "$RPC_ADDRESS" "$DATA_DIR" "$NETWORK_TYPE"
    done
fi
