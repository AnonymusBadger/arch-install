#!/usr/bin/env -S bash -e

# Clean the TTY
clear

# Load localized kayboard layout
loadkeys pl
setfont Lat2-Terminus16.psfu.gz -m 8859-2

# Network config

# Set up system clock
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

### Drive and part creation ###
clear
# Selecting boot drive
fdisk -l
echo

PS3="Select the drive "
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    break
done
