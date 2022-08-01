#!/usr/bin/env -S bash -e
DISK=$1

read -r -p "Secure wipe $DISK before install? [y/N]? " response
if [[ "${response,,}" =~ ^(yes|y)$ ]]; then
    echo "Writing random bytes to $DISK"
    cryptsetup open --type plain -s 512 -c aes-xts-plain64 -d /dev/urandom "$DISK" to_be_wiped &>/dev/null
    dd bs=1M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
    cryptsetup close to_be_wiped &>/dev/null
else
    echo "Wiping $DISK"
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
fi
