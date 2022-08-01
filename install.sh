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
select drive in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DISK=$drive
    break
done

read -r -p "Secure wipe the drive before install? [y/N]? " response
if [[ "${response,,}" =~ ^(yes|y)$ ]]; then
    echo "Writing random bytes to $DISK"
    cryptsetup open --type plain -s 512 -c aes-xts-plain64 -d /dev/urandom $DISK to_be_wiped &>/dev/null
    dd bs=1M if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
    cryptsetup close to_be_wiped &>/dev/null
else
    echo "Wiping $DISK"
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
mkfs.btrfs -L ROOT -n 32k -f $PRIMARY &>/dev/null

# Creating BTRFS subvolumes.
echo "Creating BTRFS subvolumes."
mount $PRIMARY /mnt
btrfs sub create /mnt/@ &>/dev/null
umount -R /mnt

echo "Mounting the newly created subvolumes."
mount $PRIMARY /mnt
mount -m $EFI /mnt/boot

pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware grub efibootmgr neovim man-db man-pages texinfo sudo  btrfs-progs

# Change pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf
sed -i 's/#Color = 5/Color/g' /mnt/etc/pacman.conf

# echo "Generating a new fstab."
genfstab -U /mnt >>/mnt/etc/fstab

# # Setting hostname.
read -r -p "Please enter the hostname: " hostname
echo "$hostname" >/mnt/etc/hostname

# Setting hosts file.
echo "Setting hosts file."
cat >/mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up locales.
echo "Setting locale"
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/etc/pacman.conf
sed -i 's/#pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/g' /mnt/etc/pacman.conf
echo "LANG=en_US.UTF-8" >/mnt/etc/locale.conf

# Configuring the system.
echo "Configuring chroot environment"
arch-chroot /mnt /bin/bash -e <<EOF
    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime &>/dev/null

    # Setting up clock.
    hwclock --systohc

    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null

    # Installing GRUB.
    echo "Installing GRUB on /boot."
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB  &>/dev/null

    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
EOF

# Setting root password.
echo "Setting root password."
arch-chroot /mnt /bin/passwd

echo "Unmounting new filesystem"
umount -R /mnt
