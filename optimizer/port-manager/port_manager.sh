#!/bin/bash

# Define the path to the JSON file
CHAIN_PORTS_FILE="chains_ports.json"
# Define the path to the file that stores currently used ports
CURRENT_USED_PORTS_FILE="current_used_ports.txt"
# Define the port ranges and increment values for each port type
declare -A PORT_RANGES
PORT_RANGES=(
    ["rpc_port_start"]=26650 ["rpc_port_increment"]=10
    ["p2p_port_start"]=26660 ["p2p_port_increment"]=10
    ["grpc_port_start"]=9090 ["grpc_port_increment"]=10
    ["api_port_start"]=1317 ["api_port_increment"]=10
    ["telemetry_port_start"]=26670 ["telemetry_port_increment"]=10
    ["prometheus_port_start"]=26680 ["prometheus_port_increment"]=10
    ["rosetta_port_start"]=8080 ["rosetta_port_increment"]=10
    ["pprof_port_start"]=6060 ["pprof_port_increment"]=10
    ["abci_port_start"]=26658 ["abci_port_increment"]=10
    ["grpc_web_port_start"]=9091 ["grpc_web_port_increment"]=10
)

# Function to create the JSON file if it doesn't exist
initialize_json_file() {
    if [ ! -f "$CHAIN_PORTS_FILE" ]; then
        echo '{"chains": {}}' > "$CHAIN_PORTS_FILE"
        echo "Initialized $CHAIN_PORTS_FILE with default structure."
    fi
}

# Function to get currently used ports and save them to a file
get_current_used_ports() {
    ss -tulnap | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -n | uniq > $CURRENT_USED_PORTS_FILE
    echo "Collected currently used ports and saved to $CURRENT_USED_PORTS_FILE."
}

# Function to check if a port is actually available
is_port_available() {
    local port=$1
    if (echo > /dev/tcp/127.0.0.1/$port) >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to get the next available port within a specific range
get_next_available_port() {
    local port_type=$1
    local start_port=${PORT_RANGES[${port_type}_start]}
    local increment=${PORT_RANGES[${port_type}_increment]}
    local current_port=$(jq -r --arg port_type "$port_type" --argjson start_port "$start_port" --argjson increment "$increment" '
        reduce (.chains[] | .[$port_type]) as $port ($start_port; if $port > . then $port else . end) + $increment' $CHAIN_PORTS_FILE)

    while : ; do
        if ! grep -q $current_port $CURRENT_USED_PORTS_FILE && is_port_available $current_port; then
            echo $current_port
            return
        fi
        current_port=$((current_port + increment))
    done

    echo "Error: No available ports for $port_type" >&2
    exit 1
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
    local abci_port=${10}
    local grpc_web_port=${11}

    local temp_file
    temp_file=$(mktemp)
    
    jq --arg chain_name "$chain_name" --argjson rpc_port "$rpc_port" --argjson p2p_port "$p2p_port" --argjson grpc_port "$grpc_port" \
       --argjson api_port "$api_port" --argjson telemetry_port "$telemetry_port" --argjson prometheus_port "$prometheus_port" \
       --argjson rosetta_port "$rosetta_port" --argjson pprof_port "$pprof_port" --argjson abci_port "$abci_port" --argjson grpc_web_port "$grpc_web_port" \
       '.chains[$chain_name] = {rpc_port: $rpc_port, p2p_port: $p2p_port, grpc_port: $grpc_port, api_port: $api_port, telemetry_port: $telemetry_port, prometheus_port: $prometheus_port, rosetta_port: $rosetta_port, pprof_port: $pprof_port, abci_port: $abci_port, grpc_web_port: $grpc_web_port}' \
       $CHAIN_PORTS_FILE > "$temp_file" && mv "$temp_file" $CHAIN_PORTS_FILE

    if [ $? -eq 0 ]; then
        echo "Updated $CHAIN_PORTS_FILE with new ports for $chain_name."
    else
        echo "Error updating $CHAIN_PORTS_FILE for $chain_name." >&2
        exit 1
    fi
}

# Function to update config files for the new chain
update_config_files() {
    local config_dir=$1
    local rpc_port=$2
    local p2p_port=$3
    local grpc_port=$4
    local api_port=$5
    local telemetry_port=$6
    local prometheus_port=$7
    local rosetta_port=$8
    local pprof_port=$9
    local abci_port=${10}
    local grpc_web_port=${11}

    declare -A sed_patterns=(
        ["tcp://127.0.0.1:26657"]="tcp://127.0.0.1:$rpc_port"
        ["tcp://0.0.0.0:26656"]="tcp://0.0.0.0:$p2p_port"
        ["localhost:6060"]="localhost:$pprof_port"
        [":26660"]=":$prometheus_port"
        ["tcp://0.0.0.0:1317"]="tcp://0.0.0.0:$api_port"
        [":8080"]=":$rosetta_port"
        ["0.0.0.0:9090"]="0.0.0.0:$grpc_port"
        ["0.0.0.0:9091"]="0.0.0.0:$grpc_web_port"
        ["tcp://127.0.0.1:26658"]="tcp://127.0.0.1:$abci_port"
    )

    echo "Updating configuration files in $config_dir with the following port changes:"
    for pattern in "${!sed_patterns[@]}"; do
        echo " - ${pattern} -> ${sed_patterns[$pattern]}"
        find "$config_dir" -type f -name "*.toml" -exec sed -i "s|$pattern|${sed_patterns[$pattern]}|g" {} \;
    done

    echo "Config files updated with new ports in $config_dir."
}

# Function to print port names and values
print_ports() {
    local chain_name=$1
    local rpc_port=$2
    local p2p_port=$3
    local grpc_port=$4
    local api_port=$5
    local telemetry_port=$6
    local prometheus_port=$7
    local rosetta_port=$8
    local pprof_port=$9
    local abci_port=${10}
    local grpc_web_port=${11}

    echo "Assigned ports for chain: $chain_name"
    echo " - RPC Port: $rpc_port"
    echo " - P2P Port: $p2p_port"
    echo " - gRPC Port: $grpc_port"
    echo " - API Port: $api_port"
    echo " - Telemetry Port: $telemetry_port"
    echo " - Prometheus Port: $prometheus_port"
    echo " - Rosetta Port: $rosetta_port"
    echo " - PProf Port: $pprof_port"
    echo " - ABCI Port: $abci_port"
    echo " - gRPC Web Port: $grpc_web_port"
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

    echo "Starting configuration for new chain: $chain_name"
    echo "Using configuration directory: $config_dir"

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
    local abci_port=$(get_next_available_port "abci_port")
    local grpc_web_port=$(get_next_available_port "grpc_web_port")

    # Update the JSON file with the new chain ports
    update_chain_ports "$chain_name" "$rpc_port" "$p2p_port" "$grpc_port" "$api_port" "$telemetry_port" "$prometheus_port" "$rosetta_port" "$pprof_port" "$abci_port" "$grpc_web_port"

    # Print the assigned ports
    print_ports "$chain_name" "$rpc_port" "$p2p_port" "$grpc_port" "$api_port" "$telemetry_port" "$prometheus_port" "$rosetta_port" "$pprof_port" "$abci_port" "$grpc_web_port"

    # Update the config files for the new chain
    update_config_files "$config_dir" "$rpc_port" "$p2p_port" "$grpc_port" "$api_port" "$telemetry_port" "$prometheus_port" "$rosetta_port" "$pprof_port" "$abci_port" "$grpc_web_port"
}

# Example: Add a new chain named "newchain" with an optional custom config path
# Usage: add_new_chain "newchain"
# Usage with custom path: add_new_chain "newchain:/path/to/custom/config"
add_new_chain "$1"
