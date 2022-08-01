#!/usr/bin/env -S bash -e

echo "Setting up timezone"
# Setting up timezone.
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime &
>/dev/null

# Setting up clock.
hwclock --systohc

# Setting up locales.
echo "Setting up localization"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/etc/pacman.conf
sed -i 's/#pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/g' /mnt/etc/pacman.conf
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# Generating locales.
locale-gen &
>/dev/null

# Network configuration
echo "Configuring network"
# Setting hostname.
read -r -p "Please enter the hostname: " hostname
echo "$hostname" >/etc/hostname

# Setting hosts file.
echo "Setting hosts file."
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF
