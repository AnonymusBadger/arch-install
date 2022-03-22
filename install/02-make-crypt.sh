#!/bin/bash

TOCRYPT=  # /dev/vda2 for qemu
CRYPTNAME=

# create crypt
if [ -z "$TOCRYPT" ]; then
    read -r -p "Please choose a partition to create a new crypt: " TOCRYPT
fi

cryptsetup --cipher=aes-xts-plain64 --size=512 luksFormat "$TOCRYPT"

# open it
if [ -z "$CRYPTNAME" ]; then
    read -r -p "Please choose a new cryptname" CRYPTNAME
fi

cryptsetup open "$TOCRYPT" "$CRYPTNAME"
