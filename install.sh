#!/usr/bin/env bash

. "$exec_dir/utils.sh"

# Live image setup ==========================================================================
echo "Setting up live system..."

loadkeys 'pl'
timedatectl set-timezone 'Europe/Warsaw'

# Configure pacman
sed -i '/^#Color/s/^#//' /etc/pacman.conf
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sed -i "/\[multilib]/s/^#//" /etc/pacman.conf
sed -i "/\[multilib]/{N;s/\n#/\n/}" /etc/pacman.conf

echo "Fetching mirrors..."
reflector \
	--download-timeout 2 \ 
	--save /etc/pacman.d/mirrorlist \ 
	--protocol https \ 
	--fastest 20 \ 
	--age 6 \
	--sort rate \
	--country Poland,Germany,France
	--threads 6

echo "Updating pacman database..."
pacman -Syy

# Secure wipe ===============================================================================
# TODO

# Format drive ==============================================================================
echo "Formating the drive..."

TARGET_DRIVE=$(select_disk)
sgdisk --zap-all $TARGET_DRIVE

ESP_LABEL="EFI"
CRYPT_LABEL="crypt"
SYSTEM_LABEL="cryptroot"
ESP_SIZE=1025

parted -s "$TARGET_DRIVE" \
    mklabel gpt \
    mkpart "$ESP_LABEL" fat32 1MiB "$ESP_SIZE"MiB \
    set 1 esp on \
    mkpart "$CRYPT_LABEL" "$ESP_SIZE"MiB 100%

partprobe "$TARGET_DRIVE"
sleep 1 # Sleep to changes to register

# Crypt setup ================================================================================
CRYPT="/dev/disk/by-partlabel/$CRYPT_LABEL"

echo "Creating a new crypt..."
cryptsetup luksFormat \
	--perf-no_read_workqueue \
	--perf-no_write_workqueue \
	--type luks2 \
	--cipher twofish-xts-plain64 \
	--key-size 512 \
	--iter-time 5000 \
	--align-payload=8192 \
	--hash sha512 \
	"$CRYPT"

echo "Crypt created! Opening..."
cryptsetup \
	--perf-no_read_workqueue \
	--perf-no_write_workqueue \
	--allow-discards \
	--persistent \
	open "$CRYPT" "$SYSTEM_LABEL"

# Partitioning ===============================================================================
echo "Partitioning..."
mkfs.fat -F32 -n "$ESP_LABEL" "/dev/disk/by-partlabel/$ESP_LABEL"

mkfs.btrfs --label "$SYSTEM_LABEL" "/dev/mapper/$SYSTEM_LABEL"

mount -t btrfs LABEL="$SYSTEM_LABEL" /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount -R /mnt

# Mounting ===================================================================================
echo "Mounting new partitions..."

# Mount Btrfs subvolumes
mount_btrfs() {
    local subvol=$1
    local mount_point=$2
    local mount_options="defaults,x-systemd.automount,discard=async,ssd,noatime,compress=zstd:1"
    mount --mkdir -t btrfs -o subvol="$subvol",$mount_options LABEL="$SYSTEM_LABEL" "$mount_point"
}

# Mount Btrfs subvolumes
mount_btrfs "@root" /mnt
mount_btrfs "@home" /mnt/home
mount_btrfs "@snapshots" /mnt/.snapshots
mount_btrfs "@swap" /mnt/.swap

#mount efi
EFI_MOUNT_DIR="efi"
mount --mkdir LABEL="$ESP_LABEL" "/mnt/$EFI_MOUNT_DIR"

# Make swap
echo "Creating swapfile..."
make_swap /mnt/.swap/swapfile

# Pacstrap ===================================================================================
echo "Base install..."
pacstrap -P /mnt \
	base \
       	base-devel \
       	linux-zen \
	linux-zen-headers \
       	intel-ucode \
	btrfs-progs \
       	vim \
       	sado \
	btrfs-progs \
	dracut \
	git

genfstab -L -p /mnt >> /mnt/etc/fstab

# Fix cow settings
chattr +C /mnt/tmp
chattr +C /mnt/var

# Chroot exec ==============================================================================
cp ./ /mnt/root/.
arch-chroot /mnt /root/arch-install/chroot.sh
