#!/usr/bin/env -S bash -e
DISK=$1
BOOTSIZE=513
ESP_LABEL="EFI"
PRIMARY_LABEL="primary"

parted -s "$DISK" \
    mklabel gpt \
    mkpart "$ESP_LABEL" fat32 1MiB "${BOOTSIZE}MiB" \
    set 1 esp on \
    mkpart "$PRIMARY_LABEL" "${BOOTSIZE}MiB" 100% &>/dev/null

partprobe "$DISK"
sleep 1 # Sleep to changes to register
