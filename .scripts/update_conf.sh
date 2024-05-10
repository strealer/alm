#!/bin/bash

CONFIG_FILE="/etc/default/strealer.cnf"
CONFIG_FILE_DEFAULT="src/main/resources/strlrmcmngr.cnf"


# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    # Check if the default configuration file exists
    if [ -e "$CONFIG_FILE_DEFAULT" ]; then
        # Copy the default configuration file to the specified location
        cp "$CONFIG_FILE_DEFAULT" "$CONFIG_FILE"
        echo "Configuration file copied successfully."
    else
        echo "Error: Default configuration file not found."
    fi
fi

# Check if the config file exists
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
    current_value=$(grep "^$1=" "$CONFIG_FILE" | cut -d= -f2)
#    value=$(prompt_for_value "$2" "$3")

    if [ -z "$current_value" ] || [ "$current_value" -eq 0 ]; then
#        echo "$1=$value"
        value=$(prompt_for_value "$2" "$3")
        echo "$value"
    else
#        echo "$1=$current_value"
        echo "$current_value"
    fi
}

# Check and prepare backend_host
BACKEND_HOST=$(prepare_argument "backend_host" "$BACKEND_HOST_ARG" "Backend Host")

# Check and prepare device_id
DEVICE_ID=$(prepare_argument "device_id" "$DEVICE_ID_ARG" "Device ID")

# Check and prepare remote_api_url
REMOTE_API_URL=$(prepare_argument "remote_api_url" "$REMOTE_API_URL_ARG" "Remote API URL")

# Check and prepare remote_api_key
REMOTE_API_KEY=$(prepare_argument "remote_api_key" "$REMOTE_API_KEY_ARG" "Remote API Key")

# Replace data in the config file using grep and sed
grep -q "backend_host" "$CONFIG_FILE" && sed -i "s|^backend_host=.*|backend_host=$BACKEND_HOST|" "$CONFIG_FILE" || echo "backend_host=$BACKEND_HOST" >> "$CONFIG_FILE"
grep -q "device_id" "$CONFIG_FILE" && sed -i "s|^device_id=.*|device_id=$DEVICE_ID|" "$CONFIG_FILE" || echo "device_id=$DEVICE_ID" >> "$CONFIG_FILE"
grep -q "remote_api_url" "$CONFIG_FILE" && sed -i "s|^remote_api_url=.*|remote_api_url=$REMOTE_API_URL|" "$CONFIG_FILE" || echo "remote_api_url=$REMOTE_API_URL" >> "$CONFIG_FILE"
grep -q "remote_api_key" "$CONFIG_FILE" && sed -i "s|^remote_api_key=.*|remote_api_key=$REMOTE_API_KEY|" "$CONFIG_FILE" || echo "remote_api_key=$REMOTE_API_KEY" >> "$CONFIG_FILE"

echo "Configuration updated successfully."

# Change file permissions back to read-only
chmod -w "$CONFIG_FILE"