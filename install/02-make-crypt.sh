#!/bin/bash

TOCRYPT=  # /dev/vda2 for qemu
CRYPTNAME=

if [ -z "$TOCRYPT" ]; then
    read -r -p "Please choose a partition to create a new crypt: " TOCRYPT
fi

if [ -z "$CRYPTNAME" ]; then
    read -r -p "Please choose a new cryptname: " CRYPTNAME
fi

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
echo -n "$password" | cryptsetup --cipher=aes-xts-plain64 --size=512 luksFormat "$TOCRYPT"
echo -n "$password" | cryptsetup open "$TOCRYPT" "$CRYPTNAME"
