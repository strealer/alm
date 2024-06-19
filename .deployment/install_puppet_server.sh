#!/bin/bash

### Variables

PUPPET_DEB="puppet7-release-jammy.deb"
PUPPET_URL="https://apt.puppet.com/$PUPPET_DEB"
PUPPET_PACKAGE="puppetserver"
PROFILE_FILE="/etc/profile.d/puppetlabs.sh"
PATH_TO_ADD="/opt/puppetlabs/bin"
DESIRED_HOSTNAME="puppet-master"
HOSTS_FILE="/etc/hosts"
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
  ensure_puppetserver_service
  echo "Puppet Server installation & configuration script completed successfully."
}

main
