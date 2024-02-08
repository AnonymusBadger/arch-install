#!/usr/bin/env bash 

mkdir /mnt/root/arch-install
cp -r ./* /mnt/root/arch-install
cp -r ./.* /mnt/root/arch-install

echo "Set root password"
arch-chroot /mnt passwd

systemd-nspawn -bD /mnt

