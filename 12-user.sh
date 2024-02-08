#!/usr/bin/env bash 

# Setup sudo
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel

# Create new user.
read -r -p "Please enter name for a user account: " username
echo "Adding $username with root privilege."
useradd -m $username
usermod -aG wheel $username 
usermod --shell /bin/zsh $username 
passwd "$username"

echo "Installing arch-install scripts" 
git clone --depth=1 https://github.com/AnonymusBadger/arch-install.git ~$username/arch-install
