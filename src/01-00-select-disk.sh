#!/usr/bin/env -S bash -e

# Selecting the disk
PS3="Select the disk "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    echo $ENTRY
    break
done
