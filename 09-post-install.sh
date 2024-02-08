#!/usr/bin/env bash 

mkdir /mnt/root/arch-install
cp -r ./* /mnt/root/arch-install
cp -r ./.* /mnt/root/arch-install

arch-chroot /mnt

