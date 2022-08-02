#!/usr/bin/env -S bash -e
EFI=$1
PRIMARY=$2

echo "Formatting the EFI Partition."
mkfs.vfat -n EFI "$EFI" &>/dev/null

echo "Formatting the primary partition."
mkfs.ext4 -L root "$PRIMARY" &>/dev/null
