#!/usr/bin/env bash 

. "./utils.sh"
SYSTEM_LABEL="cryptroot"
ESP_LABEL="EFI"

echo "Mounting new partitions..."

# Mount Btrfs subvolumes
mount_btrfs() {
    local subvol=$1
    local mount_point=$2
    local mount_options="defaults,discard=async,ssd,noatime,compress=zstd:1"
    mount --mkdir -t btrfs -o subvol="$subvol",$mount_options LABEL="$SYSTEM_LABEL" "$mount_point"
}

# Mount Btrfs subvolumes
mount_btrfs "@root" /mnt
mount_btrfs "@home" /mnt/home
mount_btrfs "@snapshots" /mnt/.snapshots
mount_btrfs "@swap" /mnt/.swap

#mount efi
EFI_MOUNT_DIR="efi"
mount --mkdir LABEL="$ESP_LABEL" "/mnt/$EFI_MOUNT_DIR"

# Make swap
echo "Creating swapfile..."
make_swap /mnt/.swap/swapfile
