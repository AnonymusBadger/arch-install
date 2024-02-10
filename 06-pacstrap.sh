#!/usr/bin/env bash 

echo "Base install..."
pacstrap -P /mnt \
	base \
       	base-devel \
       	linux-zen \
	linux-zen-headers \
       	intel-ucode \
	btrfs-progs \
       	vim \
       	sudo \
	btrfs-progs \
	dracut \
	less \
	git

genfstab -L -p /mnt >> /mnt/etc/fstab

# Fix cow settings
chattr +C /mnt/tmp
chattr +C /mnt/var

cp -r ./ /mnt/root/
arch-chroot /mnt
