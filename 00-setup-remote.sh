#!/usr/bin/env bash

echo "Setting up live system..."

loadkeys 'pl'
timedatectl set-timezone 'Europe/Warsaw'

# Configure pacman
sed -i '/^#Color/s/^#//' /etc/pacman.conf
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sed -i "/\[multilib]/s/^#//" /etc/pacman.conf
sed -i "/\[multilib]/{N;s/\n#/\n/}" /etc/pacman.conf

echo "Fetching mirrors..."
reflector --download-timeout 2 --save /etc/pacman.d/mirrorlist --protocol https --fastest 20 --age 6 --sort rate --country Poland,Germany,France --threads 6

echo "Updating pacman database..."
pacman -Syy
