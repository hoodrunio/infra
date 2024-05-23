#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CHAIN_NAMES=("evmos" "axelar") # Add all your chain names here

DAEMON_PREFIX="d"
SNAPSHOT_BASE_DIR="/var/www/snapshots"
DEFAULT_DATA_DIR="$HOME/.${CHAIN}d/data"

declare -A SPECIAL_CHAIN_DATA_DIRS=(
    ["axelar"]="$HOME/.axelar/data"
    # Specify other chains and their special data directories here
)

declare -A CHAIN_RPC_URLS=(
    ["evmos"]="http://localhost:36657"
    ["axelar"]="http://localhost:11117"
    # Add other chains' RPC addresses here
)

# Get the total number of cores and calculate 70% of it
TOTAL_CORES=$(nproc)
ZSTD_CORES=$(awk -v cores="$TOTAL_CORES" 'BEGIN { printf "%d\n", cores * 0.7 }')

for CHAIN in "${CHAIN_NAMES[@]}"; do
    DAEMON="${CHAIN}${DAEMON_PREFIX}"
    SNAPSHOT_DIR="${SNAPSHOT_BASE_DIR}/${CHAIN}"
    DATA_DIR="$HOME/.${CHAIN}d/data"

    if [[ -v SPECIAL_CHAIN_DATA_DIRS[$CHAIN] ]]; then
        DATA_DIR=${SPECIAL_CHAIN_DATA_DIRS[$CHAIN]}
    fi

    if ! systemctl is-active --quiet $DAEMON; then
        echo -e "${RED}Daemon $DAEMON is not running, skipping chain $CHAIN.${NC}"
        continue
    fi

    BLOCK_HEIGHT=$(curl -s ${CHAIN_RPC_URLS[$CHAIN]}/status | jq -r .result.sync_info.latest_block_height)

    if [ -z "$BLOCK_HEIGHT" ]; then
        echo -e "${RED}Failed to get block height, skipping chain $CHAIN.${NC}"
        continue
    fi

    echo -e "${GREEN}Taking snapshot: Chain = $CHAIN, Block Height = $BLOCK_HEIGHT${NC}"

    if [ ! -d "$SNAPSHOT_DIR" ]; then
        mkdir -p $SNAPSHOT_DIR
    fi

    sudo systemctl stop $DAEMON
    rm -f $SNAPSHOT_DIR/*.tar.zst

    SNAPSHOT_FILENAME="${CHAIN}_height_${BLOCK_HEIGHT}.tar.zst"
    echo -e "${YELLOW}Snapshot file name: $SNAPSHOT_FILENAME${NC}"

    # Use stdbuf to display progress bar in a single line
    stdbuf -oL tar -cf - -C $DATA_DIR . | pv -terb -s $(du -sb $DATA_DIR | awk '{print $1}') | stdbuf -oL zstd -T$ZSTD_CORES -o $SNAPSHOT_DIR/$SNAPSHOT_FILENAME

    sudo systemctl start $DAEMON

    echo -e "${CYAN}Snapshot completed: $SNAPSHOT_FILENAME${NC}"
done
