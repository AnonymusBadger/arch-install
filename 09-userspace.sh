#!/usr/bin/env bash

# Setup sudo
echo "Creatign a new user..."
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
read -r -p "Please enter name for a user account: " username
echo "Adding $username with root privilege."
useradd -m $username
usermod -aG wheel $username 
passwd "$username"

echo "Installing arch-install scripts" 
sudo -u "$username" git clone --depth=1 https://github.com/AnonymusBadger/arch-install.git "/home/$username/arch-install"

echo "Installing Paru..."
sudo -u "$username" git clone https://aur.archlinux.org/paru.git "/home/$username/paru"
cd "/home/$username/paru"
sudo -u "$username" -A makepkg -sic
cd -
rm -rf "/home/$username/paru"
