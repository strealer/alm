#!/bin/bash

CONFIG_FILE="/etc/default/strealer.cnf"
CONFIG_FILE_DEFAULT="src/main/resources/strlrmcmngr.cnf"

# Function to prompt for value if not provided
prompt_for_value() {
    if [ -n "$1" ]; then
        echo "$1"
    else
        read -p "Enter $2: " value
        echo "$value"
    fi
}

# Function to prepare argument for insertion
prepare_argument() {
    local key="$1"
    local arg_value="$2"
    local prompt_message="$3"

    current_value=$(grep "^$key=" "$CONFIG_FILE" | cut -d= -f2)
    
    if [ -z "$current_value" ] || [ "$current_value" -eq 0 ]; then
        value=$(prompt_for_value "$arg_value" "$prompt_message")
        echo "$value"
    else
        echo "$current_value"
    fi
}

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    if [ -e "$CONFIG_FILE_DEFAULT" ]; then
        cp "$CONFIG_FILE_DEFAULT" "$CONFIG_FILE"
        echo "Configuration file copied successfully."
    else
        echo "Error: Default configuration file not found."
        exit 1
    fi
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE does not exist. Exiting."
    exit 1
fi

# Change file permissions to make it writable
chmod +w "$CONFIG_FILE"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backend-host)
            BACKEND_HOST_ARG="$2"
            shift 2
            ;;
        --device-id)
            DEVICE_ID_ARG="$2"
            shift 2
            ;;
        --remote-api-url)
            REMOTE_API_URL_ARG="$2"
            shift 2
            ;;
        --remote-api-key)
            REMOTE_API_KEY_ARG="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Check and prepare values
BACKEND_HOST=$(prepare_argument "backend_host" "$BACKEND_HOST_ARG" "Backend Host")
DEVICE_ID=$(prepare_argument "device_id" "$DEVICE_ID_ARG" "Device ID")
REMOTE_API_URL=$(prepare_argument "remote_api_url" "$REMOTE_API_URL_ARG" "Remote API URL")
REMOTE_API_KEY=$(prepare_argument "remote_api_key" "$REMOTE_API_KEY_ARG" "Remote API Key")

# Update config file
update_config_file() {
    local key="$1"
    local value="$2"
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
    else
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
}

update_config_file "backend_host" "$BACKEND_HOST"
update_config_file "device_id" "$DEVICE_ID"
update_config_file "remote_api_url" "$REMOTE_API_URL"
update_config_file "remote_api_key" "$REMOTE_API_KEY"

echo "Configuration updated successfully."

# Change file permissions back to read-only
chmod -w "$CONFIG_FILE"
