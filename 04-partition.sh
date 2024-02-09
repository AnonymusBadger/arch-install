#!/usr/bin/env bash 

ESP_LABEL="EFI"
SYSTEM_LABEL="cryptroot"

echo "Partitioning..."
mkfs.fat -F32 -n "$ESP_LABEL" "/dev/disk/by-partlabel/$ESP_LABEL"

mkfs.btrfs --label "$SYSTEM_LABEL" "/dev/mapper/$SYSTEM_LABEL"

mount -t btrfs LABEL="$SYSTEM_LABEL" /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount -R /mnt
