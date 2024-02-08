#!/usr/bin/env bash 

pacstrap /mnt \
	base \
       	base-devel \
       	linux-zen \
       	linux-firmware \
	linux-headers \
       	intel-ucode \
	btrfs-progs \
       	sof-firmware \
       	neovim \
       	man-db \
       	man-pages \
       	texinfo \
       	git \
       	zsh \
       	sudo \
	btrfs-progs \
	dracut

genfstab -L -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

