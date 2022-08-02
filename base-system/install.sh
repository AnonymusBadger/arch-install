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
CRYPT="/dev/disk/by-partlabel/crypt"

/bin/bash ./01-03-make-luks.sh $CRYPT

echo "Opening the newly created LUKS Container."
cryptsetup open "$CRYPT" crypt

CRYPT="/dev/mapper/crypt"

# Formatting drives.
/bin/bash ./01-03-format.sh $EFI $CRYPT

echo "Mounting the newly created subvolumes."
mount $CRYPT /mnt
mount -m $EFI /mnt/boot/efi

pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware neovim man-db man-pages texinfo git zsh sudo

echo "Setting up base system config"
/bin/bash ./02-00-base.sh

echo "Adding users"
/bin/bash ./02-01-users.sh

arch-chroot /mnt
