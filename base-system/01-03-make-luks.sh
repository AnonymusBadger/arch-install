#!/usr/bin/env -S bash -e
CRYPT=$1

# Creating a LUKS Container for the root partition.
echo "Creating LUKS Container for the root partition."
cryptsetup luksFormat -s 512 --hash sha512 "$CRYPT"
