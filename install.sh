#!/usr/bin/env -S bash -e

# Clean the TTY
clear

# Setup live env
echo "Setting time zone"
timedatectl set-ntp true &>/dev/null
timedatectl set-timezone Europe/Warsaw &>/dev/null

echo "Updating keyring"
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf &>/dev/null
pacman -Sy archlinux-keyring --noconfirm &>/dev/null

# Select disk
fdisk -l
echo

# Selecting the disk
PS3="Select the disk "
select drives in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    break
done

read -r -p "Secure wipe the drive before install? [y/N]? " response
if [[ "${response,,}" =~ ^(yes|y)$ ]]; then
    echo "Writing random bytes to the drive"
    cryptsetup open --type plain -s 512 -c aes-xts-plain64 -d /dev/urandom $DISK to_be_wiped &>/dev/null
    dd bs=1M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
    cryptsetup close to_be_wiped &>/dev/null
else
    echo "Writing random bytes to the drive"
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
fi

# Creating a new partition scheme.
echo "Creating new partition scheme on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart EFI fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary 513MiB 100% &>/dev/null

EFI="/dev/disk/by-partlabel/EFI"
PRIMARY="/dev/disk/by-partlabel/primary"

echo "Informing the Kernel about the disk changes."
partprobe "$DISK"
sleep 1 # Sleep to changes to register

# Formatting drives.
echo "Formatting the EFI Partition."
mkfs.vfat -n EFI $EFI &>/dev/null

echo "Formatting the primary partition."
mkfs.btrfs -L ROOT -n 32k $BTRFS

# Creating BTRFS subvolumes.
echo "Creating BTRFS subvolumes."
mount $BTRFS /mnt
btrfs sub create /mnt/@ &>/dev/null
umount -R /mnt

echo "Mounting the newly created subvolumes."
mount -o $PRIMARY /mnt
mount -m $EFI /mnt/boot

pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware grub efibootmgr neovim man-db man-pages texinfo sudo  btrfs-progs
