#!/bin/bash

### Variables

PUPPET_DEB="puppet7-release-jammy.deb"
PUPPET_URL="https://apt.puppet.com/$PUPPET_DEB"
PUPPET_PACKAGE="puppet-agent"

PROFILE_FILE="/etc/profile.d/puppetlabs.sh"
PATH_TO_ADD="/opt/puppetlabs/bin"

HOSTNAME_FILE="/etc/hostname"
UUID_FILE="/etc/node_uuid"
USER_NODES_DIR="/etc/user_nodes"  # Adjusted for user nodes

PUPPET_MASTER_IP="34.122.226.249"
HOSTS_FILE="/etc/hosts"
PUPPET_CONF_FILE="/etc/puppetlabs/puppet/puppet.conf"
HOSTNAME_ENTRY="puppet-master"


### Function Definitions

# Function to check if a path exists in /etc/profile.d/puppetlabs.sh
path_exists_in_profile() {
  grep -qF "$1" "$PROFILE_FILE"
}

# Function to install Puppet
install_puppet() {
  # Install wget if not already installed
  if ! command -v wget &> /dev/null; then
    echo "wget could not be found, installing it..."
    sudo apt-get update
    sudo apt-get install -y wget
  fi

  # Download the Puppet release package if it doesn't exist
  if [ ! -f "$PUPPET_DEB" ]; then
    wget "$PUPPET_URL"
  fi

  # Install the Puppet release package
  if dpkg -s "$PUPPET_PACKAGE" &> /dev/null; then
    echo "$PUPPET_PACKAGE is already installed."
  else
    sudo apt install -y ./"$PUPPET_DEB"
    sudo apt update
    sudo apt install -y "$PUPPET_PACKAGE"
  fi

  # Clean up Puppet deb file
  if [ -f "$PUPPET_DEB" ]; then
    rm "$PUPPET_DEB"
  fi

  # Ensure /etc/profile.d/puppetlabs.sh exists and add /opt/puppetlabs/bin/ to PATH globally if not already added
  if [ ! -f "$PROFILE_FILE" ]; then
    sudo touch "$PROFILE_FILE"
    sudo chmod 644 "$PROFILE_FILE"
    echo "Created $PROFILE_FILE"
  fi

  if ! path_exists_in_profile "$PATH_TO_ADD"; then
    echo 'export PATH="/opt/puppetlabs/bin:$PATH"' | sudo tee -a "$PROFILE_FILE"
    echo "Added /opt/puppetlabs/bin/ to \$PATH globally in $PROFILE_FILE"
  else
    echo "$PATH_TO_ADD already exists in $PROFILE_FILE. Skipping addition."
  fi

  # Source the profile file to apply changes immediately
  source "$PROFILE_FILE"
  echo "Sourced $PROFILE_FILE to apply changes."
}

# Function to set hostname
set_hostname() {
  # Check if hostname already exists with USR pattern
  current_hostname=$(hostname)
  if [[ "$current_hostname" == USR-* ]]; then
    echo "Hostname already set to: $current_hostname"
    return
  fi

  # Check if UUID already exists
  if [ ! -f "$UUID_FILE" ]; then
    UUID=$(uuidgen)
    echo "$UUID" > "$UUID_FILE"
  else
    UUID=$(cat "$UUID_FILE")
  fi

  DATE=$(date +%Y%m%d)
  PREFIX="USR"

  # Generate hostname
  HOSTNAME="${PREFIX}_${UUID}_${DATE}"

  # Save to file
  echo "$HOSTNAME" > "$HOSTNAME_FILE"
  mkdir -p $USER_NODES_DIR
  touch $USER_NODES_DIR/${HOSTNAME}

  # Set hostname
  sudo hostnamectl set-hostname "$HOSTNAME"

  echo "Hostname set to: $HOSTNAME"
}

# Function to update /etc/hosts
update_hosts_file() {
  if grep -q "$HOSTNAME_ENTRY" "$HOSTS_FILE"; then
    # Check if the current IP is correct
    current_ip=$(grep "$HOSTNAME_ENTRY" "$HOSTS_FILE" | awk '{print $1}')
    if [ "$current_ip" != "$PUPPET_MASTER_IP" ]; then
      # Update the IP
      sudo sed -i "/$HOSTNAME_ENTRY/d" "$HOSTS_FILE"
      echo "$PUPPET_MASTER_IP $HOSTNAME_ENTRY" | sudo tee -a "$HOSTS_FILE" > /dev/null
      echo "Corrected the IP address for $HOSTNAME_ENTRY in /etc/hosts"
    else
      echo "The IP address for $HOSTNAME_ENTRY is already correct"
    fi
  else
    # Add the entry if it doesn't exist
    echo "$PUPPET_MASTER_IP $HOSTNAME_ENTRY" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "Added $PUPPET_MASTER_IP $HOSTNAME_ENTRY to /etc/hosts"
  fi
}

# Function to update puppet.conf
update_puppet_conf() {
  if grep -q "^\[main\]" "$PUPPET_CONF_FILE"; then
    # Check if the current server entry is correct after [main]
    if grep -A 1 "^\[main\]" "$PUPPET_CONF_FILE" | grep -q "server"; then
      current_server=$(grep -A 1 "^\[main\]" "$PUPPET_CONF_FILE" | grep "server" | awk -F "=" '{print $2}' | xargs)
      if [ "$current_server" != "$HOSTNAME_ENTRY" ]; then
        # Update the server entry
        sudo sed -i "/^\[main\]/,/^[^[]/ s/^server.*/server = $HOSTNAME_ENTRY/" "$PUPPET_CONF_FILE"
        echo "Corrected the server entry in $PUPPET_CONF_FILE"
      else
        echo "The server entry in $PUPPET_CONF_FILE is already correct"
      fi
    else
      # Add the server entry immediately after [main]
      sudo sed -i "/^\[main\]/a server = $HOSTNAME_ENTRY" "$PUPPET_CONF_FILE"
      echo "Added server entry to [main] section in $PUPPET_CONF_FILE"
    fi
  else
    # Add [main] and server entry at the appropriate place
    if grep -q "^[[:space:]]*#" "$PUPPET_CONF_FILE"; then
      # Find the last line of comments and insert after
      last_comment_line=$(grep -n "^[[:space:]]*#" "$PUPPET_CONF_FILE" | tail -n 1 | cut -d: -f1)
      sudo sed -i "$last_comment_line a \\\n[main]\nserver = $HOSTNAME_ENTRY\n" "$PUPPET_CONF_FILE"
      echo "Added [main] section and server entry after comments in $PUPPET_CONF_FILE"
    else
      # Add the [main] section and server entry at the beginning
      (echo -e "[main]\nserver = $HOSTNAME_ENTRY\n"; cat "$PUPPET_CONF_FILE") | sudo tee "$PUPPET_CONF_FILE" > /dev/null
      echo "Added [main] section and server entry at the beginning of $PUPPET_CONF_FILE"
    fi
  fi
}

# Function to ensure Puppet service is started and enabled
ensure_puppet_service() {
  if ! sudo systemctl is-active --quiet puppet; then
    sudo systemctl start puppet
    echo "Started Puppet service"
  else
    echo "Puppet service is already running"
  fi

  if ! sudo systemctl is-enabled --quiet puppet; then
    sudo systemctl enable puppet
    echo "Enabled Puppet service"
  else
    echo "Puppet service is already enabled"
  fi
}

# Function to install Docker
install_docker() {
  # Remove existing Docker packages
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -s "$pkg" &> /dev/null; then
      sudo apt-get remove -y "$pkg"
    fi
  done

  # Add Docker's official GPG key if not already added
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # Add the Docker repository to Apt sources if not already added
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
  fi

  # Install Docker packages if not already installed
  if ! dpkg -s docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &> /dev/null; then
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
}


### Main Script Execution

main() {
  install_puppet
  set_hostname
  update_hosts_file
  update_puppet_conf
  ensure_puppet_service
  install_docker
  echo "Puppet and Docker installation script completed successfully."
}

main
