#!/usr/bin/env -S bash -e

cd "$(dirname "$0")"

if [ -z ${1+x} ]; then
    DISK=$(/bin/bash ./01-00-select-disk.sh)
else
    DISK=$1
fi

if [ -z ${2+x} ]; then
    read -r -p "Specify efi partition size in MiB " response
    BOOTSIZE=$response
else
    BOOTSIZE=$1
fi

BOOTSIZE=$(($BOOTSIZE + 1))

echo $BOOTSIZE
exit

parted -s "$DISK" \
    mkpart ESP fat32 1MiB "${BOOTSIZE}MiB" \
    set 1 esp on

echo "/dev/disk/by-partlabel/ESP"
