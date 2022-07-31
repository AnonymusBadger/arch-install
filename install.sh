#!/usr/bin/env -S bash -e

# Clean the TTY
clear

# Load localized kayboard layout
loadkeys pl
setfont Lat2-Terminus16.psfu.gz -m 8859-2

# Network config

# Set up system clock
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

### Drive and part creation ###
clear
# Selecting boot drive
fdisk -l
echo

PS3="Select the drive "
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    break
done

# Wipe the drive
echo "Wiping the drive"
wipefs -af "$DRIVE" &>/dev/null
sgdisk -Zo "$DRIVE" &>/dev/null
# dd if=/dev/zero of=$DRIVE bs=4M status=progress

# Creating a new partition scheme.
echo "Creating new partition scheme on $DRIVE."
parted -s "$DRIVE" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary 513MiB 100%

ESP="/dev/disk/by-partlabel/ESP"
PRIMARY="/dev/disk/by-partlabel/primary"

echo "Informing the Kernel about the disk changes."
partprobe "$DRIVE"

# Formatting the ESP as VFAT.
echo "Formatting the EFI Partition."
mkfs.vfat -n EFI $ESP &>/dev/null

echo "Formatting the Priamry Partition."
mkfs.ext4 -L ARCH $PRIMARY &>/dev/null
