#!/usr/bin/env bash

# Hostname ===============================================================================
echo "Setting Hostname..."
read -r -p "Please enter name system hostname: " hostname
echo "$hostname" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	${hostname}
EOF

# Network ================================================================================
echo "Setting up NetworkManager..."
pacman -S --noconfirm networkmanager iwd

backend_conf_file='/etc/NetworkManager/conf.d/wifi_backend.conf'
cat > $backend_conf_file <<EOF
[device]
wifi.backend=iwd
EOF

systemctl enable NetworkManager.service
