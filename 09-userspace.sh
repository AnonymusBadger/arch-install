#!/usr/bin/env bash

# Setup sudo
echo "Creatign a new user..."
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
read -r -p "Please enter name for a user account: " username
echo "Adding $username with root privilege."
useradd -m $username
usermod -aG wheel $username 
# usermod --shell /bin/zsh $username 
passwd "$username"

echo "Installing arch-install scripts" 
git clone --depth=1 https://github.com/AnonymusBadger/arch-install.git "/home/$username/arch-install"

echo "Installing Paru..."
git clone https://aur.archlinux.org/paru.git
cd paru
su "$username" -c makepkg -sic
cd /
rm -rf ./paru
