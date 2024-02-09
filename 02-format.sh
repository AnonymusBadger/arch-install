#!/usr/bin/env bash
. "./utils.sh"

echo "Formating the drive..."

TARGET_DRIVE=$(select_disk)
sgdisk --zap-all $TARGET_DRIVE

ESP_LABEL="EFI"
ESP_SIZE=1025
CRYPT_LABEL="crypt"
SYSTEM_LABEL="cryptroot"

parted -s "$TARGET_DRIVE" \
    mklabel gpt \
    mkpart "$ESP_LABEL" fat32 1MiB "$ESP_SIZE"MiB \
    set 1 esp on \
    mkpart "$CRYPT_LABEL" "$ESP_SIZE"MiB 100%

partprobe "$TARGET_DRIVE"
sleep 1 # Sleep to changes to register
