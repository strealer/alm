#!/bin/bash

# Variables
PUPPET_DEB="puppet7-release-jammy.deb"
PUPPET_URL="https://apt.puppet.com/$PUPPET_DEB"
PUPPET_PACKAGE="puppet-agent"

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

echo "Puppet and Docker installation script completed successfully."
