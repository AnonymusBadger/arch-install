#!/usr/bin/env -S bash -e

# Cd to script directory
cd "$(dirname "$0")"

# Clean the TTY
clear

# Setup live env
/bin/bash ./src/00-setup.sh

# Select disk
fdisk -l
echo
DISK=$(/bin/bash ./src/01-00-select-disk.sh)

read -r -p "Clean drive before install? [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    echo "Cleaning drive before encryption"
    cryptsetup open --type plain -s 512 -c aes-xts-plain64 -d /dev/urandom $DISK to_be_wiped
    dd bs=1M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
    cryptsetup close to_be_wiped
    echo "DONE"
fi

# Creating a new partition scheme.
echo "Creating new partition scheme on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart EFI fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart crypt 513MiB 100%

EFI="/dev/disk/by-partlabel/EFI"
crypt="/dev/disk/by-partlabel/crypt"

echo "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as VFAT.
echo "Formatting the EFI Partition."
mkfs.vfat -n EFI $EFI

# Creating a LUKS Container for the root partition.
echo "Creating LUKS Container for the root partition."
cryptsetup luksFormat -s 512 --hash sha512 $crypt
echo "Opening the newly created LUKS Container."
cryptsetup open $crypt luks
BTRFS="/dev/mapper/luks"

echo "Formatting the LUKS container as BTRFS."
mkfs.btrfs -L ROOT $BTRFS
mount $BTRFS /mnt

# Creating BTRFS subvolumes.
echo "Creating BTRFS subvolumes."
btrfs sub create /mnt/@
btrfs sub create /mnt/@home
btrfs sub create /mnt/@boot
btrfs sub create /mnt/@opt
btrfs sub create /mnt/@root
btrfs sub create /mnt/@srv
btrfs sub create /mnt/@tmp
btrfs sub create /mnt/@usr_local
btrfs sub create /mnt/@var
btrfs sub create /mnt/@swap
btrfs sub create /mnt/@snapshots

# Make sure nothing is mounted on /mnt
echo "Mounting new file system"
# umount -Rq /mnt

# mount $PRIMARY /mnt
# mount -m -o noexec,nodev,nosuid $ESP /mnt/boot

# echo "Updating keyring"
# pacman -Sy archlinux-keyring --noconfirm
# sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
# echo "Installing the base system (it may take a while)."
# pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware e2fsprogs grub efibootmgr neovim man-db man-pages texinfo sudo

# sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf
# sed -i 's/#Color = 5/Color/g' /mnt/etc/pacman.conf

# echo "Generating a new fstab."
# genfstab -U /mnt >>/mnt/etc/fstab

# # Setting hostname.
# read -r -p "Please enter the hostname: " hostname
# echo "$hostname" >/mnt/etc/hostname

# # Setting hosts file.
# echo "Setting hosts file."
# cat >/mnt/etc/hosts <<EOF
# 127.0.0.1   localhost
# ::1         localhost
# 127.0.1.1   $hostname.localdomain   $hostname
# EOF

# # Setting up locales.
# echo "en_US.UTF-8 UTF-8" >/mnt/etc/locale.gen
# echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# # Setting up keyboard layout.
# # echo "KEYMAP=en" > /mnt/etc/vconsole.conf

# # Configuring the system.
# arch-chroot /mnt /bin/bash -e <<EOF
#     # Setting up timezone.
#     ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime &>/dev/null

#     # Setting up clock.
#     hwclock --systohc

#     # Generating locales.my keys aren't even on
#     echo "Generating locales."
#     locale-gen &>/dev/null

#     # Installing GRUB.
#     echo "Installing GRUB on /boot."
#     grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB  &>/dev/null

#     # Creating grub config file.
#     echo "Creating GRUB config file."
#     grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
# EOF

# # Setting root password.
# echo "Setting root password."
# arch-chroot /mnt /bin/passwd

# echo "Unmounting new filesystem"
# umount -R /mnt
