#!/usr/bin/env -S bash -e

cd "$(dirname "$0")"

if [ -z ${1+x} ]; then
    DISK=$(/bin/bash ./01-00-select-disk.sh)
else
    DISK=$1
fi

dd if=/dev/urandom of=$DRIVE bs=4M status=progress
