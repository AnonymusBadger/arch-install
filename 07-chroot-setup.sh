#!/usr/bin/env bash

echo "Set root password"
passwd
echo "Updating pacman..."
pacman -Syy --noconfirm

echo 'KEYMAP=pl' > /etc/vconsole.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# locale 
echo "Setting locale..."
sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen
sed -i '/^# *pl_PL.UTF-8/s/^# *//' /etc/locale.gen
locale-gen

echo "Setting Time and Date..."
# Time and Date 
ln -sf "/usr/share/zoneinfo/Europe/Warsaw" /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service
