#!/usr/bin/env -S bash -e

makeBoot() {
    # Creating a new partition scheme.
    echo "Creating new boot partition on $DISK."
    parted -s "$DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 101MiB \
        set 1 esp on
    ESP="/dev/disk/by-partlabel/ESP"

    echo "Creating new primary partition on $DISK."
    parted "$DISK" mkpart primary 101MiB 100%

    # Informing the Kernel of the changes.
    echo "Informing the Kernel about the disk changes."
    partprobe "$DISK"

    # Formatting the ESP as FAT32.
    echo "Formatting the EFI Partition as FAT32."
    mkfs.fat -F 32 $ESP &>/dev/null
}


makePrimary() {
    # Creating a new partition scheme.
    echo "Creating new primary partition on $DISK."
    parted "$DISK" mkpart primary 101MiB 100%

    # Informing the Kernel of the changes.
    echo "Informing the Kernel about the disk changes."
    partprobe "$DISK"
}

# Selecting the disk
PS3="Select the disk "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    break
done

# Deleting old partition scheme.
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
else
    echo "Quitting."
    exit
fi

# Check if boot drive
read -r -p "It this a boot drive [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    makeBoot
else
    makePrimary
fi
