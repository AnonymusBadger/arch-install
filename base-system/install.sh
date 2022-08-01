#!/usr/bin/env -S bash -e
cd "$(dirname "$0")"

# Clean the TTY
clear

# Setup live env
/bin/bash ./00-setup.sh

# Select disk
fdisk -l
echo

DISK=$(/bin/bash ./01-00-disk-select.sh)

# Wipe the drive
/bin/bash ./01-01-wipe.sh $DISK

# Partition the drive
/bin/bash ./01-02-partition.sh $DISK

# Creating a new partition scheme.
EFI="/dev/disk/by-partlabel/EFI"
PRIMARY="/dev/disk/by-partlabel/primary"

# Formatting drives.
/bin/bash ./01-03-format.sh $EFI $PRIMARY

# Creating BTRFS subvolumes.
echo "Creating BTRFS subvolumes."
mount $PRIMARY /mnt
btrfs sub create /mnt/@ &>/dev/null
umount -R /mnt

echo "Mounting the newly created subvolumes."
mount $PRIMARY /mnt
mount -m $EFI /mnt/boot/efi

pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware neovim man-db man-pages texinfo git zsh sudo

echo "Setting up base system config"
/bin/bash ./02-00-base.sh

echo "Adding users"
/bin/bash ./02-01-users.sh

arch-chroot /mnt
