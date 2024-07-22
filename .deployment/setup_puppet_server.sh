#!/bin/bash

### Variables

PUPPET_DEB="puppet8-release-jammy.deb"
PUPPET_URL="https://apt.puppet.com/$PUPPET_DEB"
PUPPET_PACKAGE="puppetserver"
PROFILE_FILE="/etc/profile.d/puppetlabs.sh"
PATH_TO_ADD="/opt/puppetlabs/bin"
DESIRED_HOSTNAME="puppet.strealer.io"
HOSTS_FILE="/etc/hosts"
PUPPET_CONF_FILE="/etc/puppetlabs/puppet/puppet.conf"
HOSTNAME_ENTRY="puppet.strealer.io"
PROFILE_FILE="/etc/profile.d/puppetlabs.sh"
PATH_TO_ADD="/opt/puppetlabs/bin"


### Function Definitions

# Function to check if a path exists in /etc/profile.d/puppetlabs.sh
path_exists_in_profile() {
  grep -qF "$1" "$PROFILE_FILE"
}

# Function to install Puppet Server
install_puppet_server() {
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

# Function to set the hostname
set_hostname() {
  current_hostname=$(hostnamectl --static)
  if [ "$current_hostname" != "$DESIRED_HOSTNAME" ]; then
    sudo hostnamectl set-hostname "$DESIRED_HOSTNAME"
    echo "Hostname set to $DESIRED_HOSTNAME"
  else
    echo "Hostname is already set to $DESIRED_HOSTNAME"
  fi
}

# Function to update /etc/hosts
update_hosts_file() {
  if ! grep -q "127.0.0.1 $DESIRED_HOSTNAME" "$HOSTS_FILE"; then
    echo "127.0.0.1 $DESIRED_HOSTNAME" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "Added $DESIRED_HOSTNAME to $HOSTS_FILE"
  else
    echo "$DESIRED_HOSTNAME already exists in $HOSTS_FILE"
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

# Function to update autosign.conf
update_autosign_conf() {
  AUTOSIGN_CONF_FILE="/etc/puppetlabs/puppet/autosign.conf"
  AUTOSIGN_ENTRIES="comp-*\nusr-*"

  # Check if the autosign entries already exist
  for entry in $(echo -e "$AUTOSIGN_ENTRIES"); do
    if ! grep -q "$entry" "$AUTOSIGN_CONF_FILE"; then
      echo "$entry" | sudo tee -a "$AUTOSIGN_CONF_FILE" > /dev/null
      echo "Added $entry to $AUTOSIGN_CONF_FILE"
    fi
  done
}

# Function to ensure Puppet server service is started and enabled
ensure_puppetserver_service() {
  if ! sudo systemctl is-active --quiet puppetserver; then
    sudo systemctl start puppetserver
    echo "Started puppetserver service"
  else
    echo "puppetserver service is already running"
  fi

  if ! sudo systemctl is-enabled --quiet puppetserver; then
    sudo systemctl enable puppetserver
    echo "Enabled puppetserver service"
  else
    echo "puppetserver service is already enabled"
  fi
}


### Main Script Execution

main() {
  install_puppet_server
  set_hostname
  update_hosts_file
  update_puppet_conf
  update_autosign_conf
  ensure_puppetserver_service
  echo "Puppet Server installation & configuration script completed successfully."
}

main
