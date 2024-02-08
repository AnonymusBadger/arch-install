#!/usr/bin/env bash 

mkdir /mnt/root/arch-install
cp -r ./* /mnt/root/arch-install
cp -r ./.* /mnt/root/arch-install
systemd-nspawn -bD /mnt

