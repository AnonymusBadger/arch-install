#!/usr/bin/env -S bash -e

# Change pacman.conf
echo "Seting up pacman"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
sed -i 's/#Color = 5/Color/g' /etc/pacman.conf
