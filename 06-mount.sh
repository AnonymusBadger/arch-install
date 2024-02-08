#!/usr/bin/env bash 

# Define mount options
mount_options="defaults,x-mount.mkdir"
btrfs_mount_options="$mount_options,compress=lzo,ssd,noatime"
swap_mount_options="x-mount.mkdir,space_cache,ssd,discard=async,compress=no"

# Mount Btrfs subvolumes
mount_btrfs() {
    local subvol=$1
    local label=$2
    local options=$3
    local mount_point=$4
    mount -t btrfs -o subvol="$subvol",$options LABEL="$label" "$mount_point"
}

# Make swap
make_swap() {
    chattr +C /mnt/.swap
    ./utils/swapfile-maker.sh
}

label="system"

# Mount Btrfs subvolumes
mount_btrfs "@root" "$label" "$btrfs_mount_options" /mnt
mount_btrfs "@home" "$label" "$btrfs_mount_options" /mnt/home
mount_btrfs "@snapshots" "$label" "$btrfs_mount_options" /mnt/.snapshots
mount_btrfs "@swap" "$label" "$swap_mount_options" /mnt/.swap

# Make swap
make_swap

#mount efi
mkdir -p /mnt/boot
mount LABEL=EFI /mnt/boot

