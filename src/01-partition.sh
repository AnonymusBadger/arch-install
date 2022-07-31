#!/usr/bin/env -S bash -e

BOOTSIZE=513

makePartitions() {
    # Creating a new partition scheme.
    echo "Creating new boot partition on $DISK."
    parted -s "$DISK" \
        mklabel gpt \
        mkpart ESP fat32 1MiB "${BOOTSIZE}MiB" \
        set 1 esp on
    ESP="/dev/disk/by-partlabel/ESP"

    echo "Creating new primary partition on $DISK."
    parted "$DISK" mkpart primary "${BOOTSIZE}MiB" 100%

    # Informing the Kernel of the changes.
    echo "Informing the Kernel about the disk changes."
    partprobe "$DISK"

    # Formatting the ESP as FAT32.
    echo "Formatting the EFI Partition as FAT32."
    mkfs.fat -F 32 $ESP &
    >/dev/null
}
