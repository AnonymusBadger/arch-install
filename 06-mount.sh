#!/usr/bin/env bash 

o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,noatime
o_swap=x-mount.mkdir,space_cache,ssd,discard=async,compress=no

mount -t btrfs -o subvol=@root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=@home,$o_btrfs LABEL=system /mnt/home
mount -t btrfs -o subvol=@snapshots,$o_btrfs LABEL=system /mnt/.snapshots
mount -t btrfs -o subvol=@swap,$o_swap LABEL=system /mnt/.swap

# makeswap
SWAP_SIZE=32768
chattr +C /mnt/.swap
dd if=/dev/zero of=/mnt/.swap/swapfile bs=1M count=$SWAP_SIZE status=progress
chmod 0600 /mnt/.swap/swapfile
mkswap -U clear /mnt/.swap/swapfile
swapon /mnt/.swap/swapfile

#mount efi
mount --mkdir LABEL=EFI /mnt/efi

btrfs subvolume list /mnt
ls /mnt
