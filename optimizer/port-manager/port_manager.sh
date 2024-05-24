#!/bin/bash

# Define the path to the JSON file
CHAIN_PORTS_FILE="chains_ports.json"
# Define the path to the file that stores currently used ports
CURRENT_USED_PORTS_FILE="current_used_ports.txt"

# Function to create the JSON file if it doesn't exist
initialize_json_file() {
    if [ ! -f "$CHAIN_PORTS_FILE" ]; then
        echo '{"chains": {}}' > "$CHAIN_PORTS_FILE"
    fi
}

# Function to get currently used ports and save them to a file
get_current_used_ports() {
    ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -n | uniq > $CURRENT_USED_PORTS_FILE
}

# Function to read JSON file and get the next available port
get_next_available_port() {
    local port_type=$1
    local current_port=$(jq -r --arg port_type "$port_type" 'reduce (.chains[] | .[$port_type]) as $port (0; if $port > . then $port else . end) + 10' $CHAIN_PORTS_FILE)
    while grep -q $current_port $CURRENT_USED_PORTS_FILE; do
        current_port=$((current_port + 10))
    done
    echo $current_port
}

# Function to update JSON file with new chain ports
update_chain_ports() {
    local chain_name=$1
    local rpc_port=$2
    local p2p_port=$3
    local grpc_port=$4
    local api_port=$5
    local telemetry_port=$6
    local prometheus_port=$7
    local rosetta_port=$8
    local pprof_port=$9

    jq --arg chain_name "$chain_name" --argjson rpc_port "$rpc_port" --argjson p2p_port "$p2p_port" --argjson grpc_port "$grpc_port" \
       --argjson api_port "$api_port" --argjson telemetry_port "$telemetry_port" --argjson prometheus_port "$prometheus_port" \
       --argjson rosetta_port "$rosetta_port" --argjson pprof_port "$pprof_port" \
       '.chains[$chain_name] = {rpc_port: $rpc_port, p2p_port: $p2p_port, grpc_port: $grpc_port, api_port: $api_port, telemetry_port: $telemetry_port, prometheus_port: $prometheus_port, rosetta_port: $rosetta_port, pprof_port: $pprof_port}' \
       $CHAIN_PORTS_FILE > tmp.$$.json && mv tmp.$$.json $CHAIN_PORTS_FILE
}

# Function to update config files for the new chain
update_config_files() {
    local chain_name=$1
    local config_dir=$2
    local rpc_port=$3
    local p2p_port=$4
    local grpc_port=$5
    local api_port=$6
    local telemetry_port=$7
    local prometheus_port=$8
    local rosetta_port=$9
    local pprof_port=${10}

    declare -A sed_patterns=(
        ["laddr = \"tcp://0.0.0.0:26657\""]="laddr = \"tcp://0.0.0.0:$rpc_port\""
        ["laddr = \"tcp://127.0.0.1:26657\""]="laddr = \"tcp://127.0.0.1:$rpc_port\""
        ["laddr = \"tcp://0.0.0.0:26656\""]="laddr = \"tcp://0.0.0.0:$p2p_port\""
        ["laddr = \"tcp://127.0.0.1:26656\""]="laddr = \"tcp://127.0.0.1:$p2p_port\""
        ["address = \"0.0.0.0:26660\""]="address = \"0.0.0.0:$telemetry_port\""
        ["address = \"127.0.0.1:26660\""]="address = \"127.0.0.1:$telemetry_port\""
        ["prometheus_listen_addr = \":26660\""]="prometheus_listen_addr = \":$prometheus_port\""
        ["address = \"0.0.0.0:9090\""]="address = \"0.0.0.0:$grpc_port\""
        ["address = \"127.0.0.1:9090\""]="address = \"127.0.0.1:$grpc_port\""
        ["api_address = \"tcp://0.0.0.0:1317\""]="api_address = \"tcp://0.0.0.0:$api_port\""
        ["api_address = \"tcp://127.0.0.1:1317\""]="api_address = \"tcp://127.0.0.1:$api_port\""
        ["rosetta_address = \"tcp://0.0.0.0:8080\""]="rosetta_address = \"tcp://0.0.0.0:$rosetta_port\""
        ["rosetta_address = \"tcp://127.0.0.1:8080\""]="rosetta_address = \"tcp://127.0.0.1:$rosetta_port\""
        ["pprof_laddr = \"localhost:6060\""]="pprof_laddr = \"localhost:$pprof_port\""
        ["pprof_laddr = \"0.0.0.0:6060\""]="pprof_laddr = \"0.0.0.0:$pprof_port\""
        ["pprof_laddr = \"127.0.0.1:6060\""]="pprof_laddr = \"127.0.0.1:$pprof_port\""
    )

    for pattern in "${!sed_patterns[@]}"; do
        sed -i "s/$pattern/${sed_patterns[$pattern]}/" "$config_dir/config.toml"
        sed -i "s/$pattern/${sed_patterns[$pattern]}/" "$config_dir/app.toml"
    done

    echo "New chain config files updated with new ports for $chain_name."
}

# Add new chain
add_new_chain() {
    local chain_input=$1
    IFS=':' read -r chain_name custom_config_path <<< "$chain_input"
    
    if [ -z "$custom_config_path" ]; then
        config_dir="$HOME/${chain_name}d/config"
    else
        config_dir="$custom_config_path"
    fi

    # Initialize JSON file if it doesn't exist
    initialize_json_file

    # Get the currently used ports
    get_current_used_ports

    # Get the next available ports
    local rpc_port=$(get_next_available_port "rpc_port")
    local p2p_port=$(get_next_available_port "p2p_port")
    local grpc_port=$(get_next_available_port "grpc_port")
    local api_port=$(get_next_available_port "api_port")
    local telemetry_port=$(get_next_available_port "telemetry_port")
    local prometheus_port=$(get_next_available_port "prometheus_port")
    local rosetta_port=$(get_next_available_port "rosetta_port")
    local pprof_port=$(get_next_available_port "pprof_port")

    # Update the JSON file with the new chain ports
    update_chain_ports "$chain_name" "$rpc_port" "$p2p_port" "$grpc_port" "$api_port" "$telemetry_port" "$prometheus_port" "$rosetta_port" "$pprof_port"

    # Update the config files for the new chain
    update_config_files "$chain_name" "$config_dir" "$rpc_port" "$p2p_port" "$grpc_port" "$api_port" "$telemetry_port" "$prometheus_port" "$rosetta_port" "$pprof_port"
}

# Example: Add a new chain named "newchain" with an optional custom config path
# Usage: add_new_chain "newchain"
# Usage with custom path: add_new_chain "newchain:/path/to/custom/config"
add_new_chain "$1"
