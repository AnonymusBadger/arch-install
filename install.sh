#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear

# set Installer timezone
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

#update live env
pacman -Syu

selectDisk() {
    PS3="Select the disk "
    select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
    do
        DISK=$ENTRY
        break
    done
}
