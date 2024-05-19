#!/bin/bash

# Stop Nginx service if it's running
sudo systemctl stop nginx

# Remove Nginx package
#sudo apt-get purge nginx nginx-common nginx-core -y
sudo apt-get autoremove -y
sudo apt-get autoclean

# Remove Nginx configuration files
sudo rm -rf /etc/nginx

# Remove Nginx log files
sudo rm -rf /var/log/nginx

# Remove Nginx cache directory
sudo rm -rf /usr/share/nginx/strealer_cache

echo "Nginx and its configuration files have been removed successfully."
