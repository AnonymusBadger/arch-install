#!/usr/bin/env -S bash -e

# Change pacman.conf
echo "Seting up pacman"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf
sed -i 's/#Color = 5/Color/g' /mnt/etc/pacman.conf
