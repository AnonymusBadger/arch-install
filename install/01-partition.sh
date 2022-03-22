#!/bin/bash

## Please enable UEFI first

DRIVE=  # /dev/vda for qemu, /dev/sda for VirtualBox
IS_BOOT= # true / false

makeBoot() {
    parted "$DRIVE" mklabel gpt
    parted "$DRIVE" mkpart ESP fat32 1MiB 301MiB
    parted "$DRIVE" set 1 esp on
    parted "$DRIVE" mkpart primary 301MiB 100%
    mkfs.fat -F32 "${DRIVE}1"
}

makePart() {
    parted "$DRIVE" mklabel gpt
    parted "$DRIVE" mkpart primary 1MiB 100%
}

choice() {
    read -r -p "Is this a boot drive [y/n]" choice
    case $choice in
        y ) IS_BOOT=true
            ;;
        n ) IS_BOOT=false
            ;;
        * ) echo "You did not enter a valid response"
            choice
    esac
}

if [ -z "$DRIVE" ]; then
    read -r -p "Please choose the drive: " DRIVE
fi

if [ -z "$IS_BOOT" ]; then
    choice
fi

if $IS_BOOT
    then
        makeBoot
    else
        makePart
fi

lsblk
