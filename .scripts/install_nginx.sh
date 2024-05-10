#!/bin/bash

# Step 2: Calculate available cache size
total_disk_size=$(df --output=size / | awk 'NR==2')
available_cache_size_bytes=$(( (total_disk_size * 1024) - (20 * 1024 * 1024 * 1024) ))
available_cache_size_gb=$(( available_cache_size_bytes / (1024 * 1024 * 1024) ))
echo $total_disk_size
echo $available_cache_size_gb

# Check if available cache size is smaller than 1GB
if [ $available_cache_size_gb -lt 1 ]; then
    echo "Error: Insufficient available cache size. Exiting..."
    exit 1
fi

# Step 3: Install/update nginx
# sudo apt-get install nginx -y

# Step 4: Configure nginx
backend_host=$(grep "^backend_host=" /etc/default/strealer.cnf | cut -d= -f2)
nginx_config="# Define a cache zone to store cached responses\nproxy_cache_path /usr/share/nginx/strealer_cache levels=1:2 keys_zone=strealer_cache:50m max_size=${available_cache_size_gb}G inactive=24h use_temp_path=off;\n\n# Define strealer access log format for backend and frontend\nlog_format strealer_be_log_format 'BK | \$time_iso8601 | \$status | \$request | \$body_bytes_sent';\nlog_format strealer_fe_log_format 'FT | \$time_iso8601 | \$status | \$request | \$body_bytes_sent | \$upstream_cache_status';\nmap \$request_uri \$skip_favicon {\n    default 1;\n    ~*^/favicon\\.ico\$ 0;\n}\n\nserver {\n    listen 8080 default_server;\n    listen [::]:8080 default_server;\n    access_log /var/log/nginx/access.log strealer_be_log_format if=\$skip_favicon;\n    error_log /var/log/nginx/error.log;\n    location / {\n        resolver 8.8.8.8 valid=600s;\n        set \$backend_servers ${backend_host};\n        proxy_pass \$backend_servers;\n    }\n}\n\nserver {\n    listen 80;\n    listen [::]:80;\n    access_log /var/log/nginx/access.log strealer_fe_log_format if=\$skip_favicon;\n    error_log /var/log/nginx/error.log;\n    location / {\n        proxy_pass http://127.0.0.1:8080;\n        proxy_cache strealer_cache;\n        proxy_cache_valid 200 304 24h;\n        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;\n        proxy_cache_background_update on;\n        proxy_cache_lock on;\n        proxy_cache_lock_timeout 5s;\n        proxy_cache_revalidate on;\n        proxy_ignore_headers Cache-Control;\n        add_header Cache-Control \"no-cache, no-store, private, must-revalidate\" always;\n        add_header Pragma \"no-cache\" always;\n        add_header Expires \"0\" always;\n        add_header Accept-Ranges bytes;\n        add_header X-Cache-Status \$upstream_cache_status;\n        proxy_set_header If-None-Match \$http_etag;\n        proxy_set_header If-Modified-Since \$upstream_http_last_modified;\n    }\n}"

# Backup the default configuration
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# Write the new configuration to the default file
echo -e "$nginx_config" | tee /etc/nginx/sites-available/default

# Restart nginx to apply changes
nginx -s reload

echo "Nginx installation and configuration completed successfully."