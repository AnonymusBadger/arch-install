#!/bin/bash

TOCRYPT=  # /dev/vda2 for qemu
CRYPTNAME=

# create crypt
if [ -z "$TOCRYPT" ]; then
    read -n -p "Please choose a partition to be formatted to LUKS: " TOCRYPT
fi

cryptsetup --cipher=aes-xts-plain64 -s 512 luksFormat "$TOCRYPT"

# open it
if [ -z "$CRYPTNAME" ]; then
    read -n -p "Please choose a new cryptname" CRYPTNAME
fi
cryptsetup open "$TOCRYPT" "$CRYPTNAME"
