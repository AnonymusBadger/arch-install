#!/bin/bash

## Please enable UEFI first

DRIVE=  # /dev/vda for qemu, /dev/sda for VirtualBox
IS_BOOT= # true / false

if [ -z "$DRIVE" ]; then
    read -r -p "Please choose the drive: " PART
fi

makeBoot() {
    parted "$DRIVE" mklabel gpt
    parted "$DRIVE" mkpart ESP fat32 1MiB 512MiB
    parted "$DRIVE" mkpart primary 512MiB 100%
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
        * ) print "You did not enter a valid response"
            choice
    esac
}

if [ -z "$IS_BOOT" ]; then
    choice
fi

if [ IS_BOOT ]
    then
        makeBoot
    else
        makePart
fi

lsblk
