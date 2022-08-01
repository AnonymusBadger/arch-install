#!/usr/bin/env -S bash -e
EFI=$1
BTRFS=$2

echo "Formatting the EFI Partition."
mkfs.vfat -n EFI "$EFI" &>/dev/null

echo "Formatting the primary partition."
mkfs.btrfs -L ROOT -n 32k -f "$BTRFS" &>/dev/null
