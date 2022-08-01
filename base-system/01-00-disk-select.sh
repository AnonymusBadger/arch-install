#!/usr/bin/env -S bash -e
# Select disk
fdisk -l
echo

# Selecting the disk
PS3="Select the disk "
select drive in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    echo "$drive"
    break
done
