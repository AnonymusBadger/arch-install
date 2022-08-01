#!/usr/bin/env -S bash -e

# Setup live env
echo "Setting time zone"
timedatectl set-ntp true &
>/dev/null
timedatectl set-timezone Europe/Warsaw &
>/dev/null

echo "Updating keyring"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf &
>/dev/null
pacman -Sy archlinux-keyring --noconfirm &
>/dev/null
