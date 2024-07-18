#!/bin/bash

# Variables
PUPPET_DEB="puppet8-release-jammy.deb"
PUPPET_URL="https://apt.puppet.com/$PUPPET_DEB"
PUPPET_PACKAGE="puppet-agent"

PROFILE_FILE="/etc/profile.d/puppetlabs.sh"
PATH_TO_ADD="/opt/puppetlabs/bin"

HOSTNAME_FILE="/etc/hostname"
UUID_FILE="/etc/node_uuid"
USER_NODES_DIR="/etc/user_nodes"  # Adjusted for user nodes

PUPPET_MASTER="puppet.strealer.io"
PUPPET_CONF_FILE="/etc/puppetlabs/puppet/puppet.conf"

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
  # Check if hostname already exists with usr pattern
  current_hostname=$(hostname)
  if [[ "$current_hostname" == usr-* ]]; then
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
  PREFIX="usr"

  # Generate hostname
  HOSTNAME="${PREFIX}-${UUID}-${DATE}"

  # Save to file
  echo "$HOSTNAME" > "$HOSTNAME_FILE"
  mkdir -p $USER_NODES_DIR
  touch $USER_NODES_DIR/${HOSTNAME}

  # Set hostname
  sudo hostnamectl set-hostname "$HOSTNAME"

  echo "Hostname set to: $HOSTNAME"
}

# Function to update puppet.conf
update_puppet_conf() {
  HOSTNAME=$(hostname)
  WAIT_FOR_CERT=60

  if grep -q "^\[main\]" "$PUPPET_CONF_FILE"; then
    # Check if the current server entry is correct after [main]
    if grep -A 1 "^\[main\]" "$PUPPET_CONF_FILE" | grep -q "server"; then
      current_server=$(grep -A 1 "^\[main\]" "$PUPPET_CONF_FILE" | grep "server" | awk -F "=" '{print $2}' | xargs)
      if [ "$current_server" != "$PUPPET_MASTER" ]; then
        # Update the server entry
        sudo sed -i "/^\[main\]/,/^[^[]/ s/^server.*/server = $PUPPET_MASTER/" "$PUPPET_CONF_FILE"
        echo "Corrected the server entry in $PUPPET_CONF_FILE"
      else
        echo "The server entry in $PUPPET_CONF_FILE is already correct"
      fi
    else
      # Add the server entry immediately after [main]
      sudo sed -i "/^\[main\]/a server = $PUPPET_MASTER" "$PUPPET_CONF_FILE"
      echo "Added server entry to [main] section in $PUPPET_CONF_FILE"
    fi
  else
    # Add [main] and server entry at the appropriate place
    if grep -q "^[[:space:]]*#" "$PUPPET_CONF_FILE"; then
      # Find the last line of comments and insert after
      last_comment_line=$(grep -n "^[[:space:]]*#" "$PUPPET_CONF_FILE" | tail -n 1 | cut -d: -f1)
      sudo sed -i "$last_comment_line a \\\n[main]\nserver = $PUPPET_MASTER\n" "$PUPPET_CONF_FILE"
      echo "Added [main] section and server entry after comments in $PUPPET_CONF_FILE"
    else
      # Add the [main] section and server entry at the beginning
      (echo -e "[main]\nserver = $PUPPET_MASTER\n"; cat "$PUPPET_CONF_FILE") | sudo tee "$PUPPET_CONF_FILE" > /dev/null
      echo "Added [main] section and server entry at the beginning of $PUPPET_CONF_FILE"
    fi
  fi

  if grep -q "^\[agent\]" "$PUPPET_CONF_FILE"; then
    # Check if the current certname entry is correct after [agent]
    if grep -A 1 "^\[agent\]" "$PUPPET_CONF_FILE" | grep -q "certname"; then
      current_certname=$(grep -A 1 "^\[agent\]" "$PUPPET_CONF_FILE" | grep "certname" | awk -F "=" '{print $2}' | xargs)
      if [ "$current_certname" != "$HOSTNAME" ]; then
        # Update the certname entry
        sudo sed -i "/^\[agent\]/,/^[^[]/ s/^certname.*/certname = $HOSTNAME/" "$PUPPET_CONF_FILE"
        echo "Corrected the certname entry in $PUPPET_CONF_FILE"
      else
        echo "The certname entry in $PUPPET_CONF_FILE is already correct"
      fi
    else
      # Add the certname entry immediately after [agent]
      sudo sed -i "/^\[agent\]/a certname = $HOSTNAME" "$PUPPET_CONF_FILE"
      echo "Added certname entry to [agent] section in $PUPPET_CONF_FILE"
    fi
    # Check if the waitforcert entry is correct after [agent]
    if grep -A 1 "^\[agent\]" "$PUPPET_CONF_FILE" | grep -q "waitforcert"; then
      current_waitforcert=$(grep -A 1 "^\[agent\]" "$PUPPET_CONF_FILE" | grep "waitforcert" | awk -F "=" '{print $2}' | xargs)
      if [ "$current_waitforcert" != "$WAIT_FOR_CERT" ]; then
        # Update the waitforcert entry
        sudo sed -i "/^\[agent\]/,/^[^[]/ s/^waitforcert.*/waitforcert = $WAIT_FOR_CERT/" "$PUPPET_CONF_FILE"
        echo "Corrected the waitforcert entry in $PUPPET_CONF_FILE"
      else
        echo "The waitforcert entry in $PUPPET_CONF_FILE is already correct"
      fi
    else
      # Add the waitforcert entry immediately after [agent]
      sudo sed -i "/^\[agent\]/a waitforcert = $WAIT_FOR_CERT" "$PUPPET_CONF_FILE"
      echo "Added waitforcert entry to [agent] section in $PUPPET_CONF_FILE"
    fi
  else
    # Add [agent] section and its entries
    if grep -q "^[[:space:]]*#" "$PUPPET_CONF_FILE"; then
      # Find the last line of comments and insert after
      last_comment_line=$(grep -n "^[[:space:]]*#" "$PUPPET_CONF_FILE" | tail -n 1 | cut -d: -f1)
      sudo sed -i "$last_comment_line a \\\n[agent]\ncertname = $HOSTNAME\nwaitforcert = $WAIT_FOR_CERT\n" "$PUPPET_CONF_FILE"
      echo "Added [agent] section and its entries after comments in $PUPPET_CONF_FILE"
    else
      # Add the [agent] section and its entries at the end
      echo -e "\n[agent]\ncertname = $HOSTNAME\nwaitforcert = $WAIT_FOR_CERT" | sudo tee -a "$PUPPET_CONF_FILE" > /dev/null
      echo "Added [agent] section and its entries at the end of $PUPPET_CONF_FILE"
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
  
  # Restart Puppet service
  sudo systemctl restart puppet
  echo "Restarted Puppet service"
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
  update_puppet_conf
  ensure_puppet_service
  install_docker
  echo "Puppet and Docker installation script completed successfully."
}

main
