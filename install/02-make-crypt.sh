#!/usr/bin/env -S bash -e

# Selecting the partition
PS3="Select the partition "
select ENTRY in $(lsblk -pnroNAME | grep -P "/dev/sd|nvme|vd");
do
    PARTITON=$ENTRY
    break
done

read -r -p "Please choose a new cryptname: " CRYPTNAME

while true; do
    read -r -s -p "Insert password for the LUKS container: " password
    while [ -z "$password" ]; do
        echo
        echo "You need to enter a password for the LUKS Container in order to continue."
        read -r -s -p "Insert password for the LUKS container: " password
        [ -n "$password" ] && break
    done
    echo
    read -r -s -p "Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Passwords don't match, try again."
done
echo -n "$password" | cryptsetup --cipher=aes-xts-plain64 --size=512 luksFormat "$PARTITON"
echo -n "$password" | cryptsetup open "$PARTITON" "$CRYPTNAME"
