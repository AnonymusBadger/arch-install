#!/usr/bin/env bash 

mkdir /mnt/arch-install
cp -r ./* /mnt/arch-install
cp -r ./.* /mnt/arch-install
systemd-nspawn -bD /mnt

