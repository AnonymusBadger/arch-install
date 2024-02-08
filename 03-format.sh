#!/usr/bin/env bash

DISK=$(./utils/disk-select.sh)
ESP_LABEL="EFI"
PRIMARY_LABEL="crypt"

sgdisk --zap-all $DRIVE

parted -s "$DISK" \
    mklabel gpt \
    mkpart "$ESP_LABEL" fat32 1MiB "512MiB" \
    set 1 esp on \
    mkpart "$PRIMARY_LABEL" "512MiB" 100% &>/dev/null

partprobe "$DISK"
sleep 1 # Sleep to changes to register
