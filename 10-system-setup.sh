#!/usr/bin/env bash 

pacman -Syy
passwd

# locale
sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen
sed -i '/^# *pl_PL.UTF-8/s/^# *//' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8

# Time and Date
timedatectl set-ntp 1
timedatectl set-timezone Europe/Warsaw
hwclock --systohc

# Hostname
read -r -p "Please enter name system hostname: " hostname
hostnamectl set-hostname "$hostname"
echo "127.0.1.1	myhostname.localdomain	$hostname" >> /etc/hosts

# Network
pacman -S networkmanager iwd

backend_conf_file='/etc/NetworkManager/conf.d/wifi_backend.conf'
touch $backend_conf_file
echo '[device]' > $backend_conf_file
echo 'wifi.backend=iwd' >> $backend_conf_file

systemctl enable NetworkManager.service

# iniframs
echo 'KEYMAP=pl' > /etc/vconsole.conf
sed -i 's/^HOOKS/HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

