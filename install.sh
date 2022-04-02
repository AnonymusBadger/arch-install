#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear

# set Installer timezone
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

# update live env
pacman -Syu

### Drive and part creation ###


# Selecting boot drive
PS3="Select the disk "
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    break
done

# Wiping the drive
read -r -p "This will delete the current partition table on $DRIVE. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    wipefs -af "$DRIVE" &>/dev/null
    sgdisk -Zo "$DRIVE" &>/dev/null
    return 0
else
    echo "Quitting."
fi

# Creating a new partition scheme.
echo "Creating new boot partition on $DRIVE."
parted -s "$DRIVE" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 101MiB \
    set 1 esp on
ESP="/dev/disk/by-partlabel/ESP"

echo "Creating new primary partition on $DRIVE."
parted "$DRIVE" mkpart primary 101MiB 100%

# Informing the Kernel of the changes.
echo "Informing the Kernel about the disk changes."
partprobe "$DRIVE"

# Formatting the ESP as VFAT.
echo "Formatting the EFI Partition."
mkfs.vfat $ESP &>/dev/null
