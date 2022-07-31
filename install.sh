#!/usr/bin/env -S bash -e

# Cd to script directory
cd "$(dirname "$0")"

# Clean the TTY
clear

# Setup live env
# /bin/bash ./src/00-setup.sh

### Drive and partition creation ###
/bin/bash ./src/01-04-make-efi.sh
exit
# Select disk
fdisk -l
echo
DISK=$(/bin/bash ./src/01-00-select-disk.sh)

# Wiping table
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    /bin/bash ./src/01-01-wipe.sh $DISK
else
    echo "Quitting."
    exit
fi

# Writing random bytes to the disk
read -r -p "Do you wish to write random bytes to the $DISK. [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    /bin/bash ./src/01-02-randomize.sh $DISK
fi

# Partitioning
BOOTSIZE=512

echo "Creating new partition scheme on $DISK."
echo "Creating new boot partition on $DISK."
EFI=$(/bin/bash ./src/01-03-make-gpt.sh $DISK $BOOTSIZE)

read -r -p "Encrypt primary partition? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
fi

exit

# Creating a new partition scheme.
echo "Creating new partition scheme on $DRIVE."
parted -s "$DRIVE" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary 513MiB 100%

ESP="/dev/disk/by-partlabel/ESP"
PRIMARY="/dev/disk/by-partlabel/primary"

echo "Informing the Kernel about the disk changes."
partprobe "$DRIVE"

# Formatting the ESP as VFAT.
echo "Formatting the EFI Partition."
mkfs.vfat -n EFI $ESP &>/dev/null

echo "Formatting the Priamry Partition."
mkfs.ext4 -L ARCH $PRIMARY &>/dev/null

# Mount newly created filesystem

# Make sure nothing is mounted on /mnt
echo "Mounting new file system"
# umount -Rq /mnt

mount $PRIMARY /mnt
mount -m -o noexec,nodev,nosuid $ESP /mnt/boot

echo "Updating keyring"
pacman -Sy archlinux-keyring --noconfirm
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
echo "Installing the base system (it may take a while)."
pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware e2fsprogs grub efibootmgr neovim man-db man-pages texinfo sudo

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf
sed -i 's/#Color = 5/Color/g' /mnt/etc/pacman.conf

echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting hostname.
read -r -p "Please enter the hostname: " hostname
echo "$hostname" > /mnt/etc/hostname

# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Setting up locales.
echo "en_US.UTF-8 UTF-8"  > /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Setting up keyboard layout.
# echo "KEYMAP=en" > /mnt/etc/vconsole.conf

# Configuring the system.
arch-chroot /mnt /bin/bash -e <<EOF
    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime &>/dev/null

    # Setting up clock.
    hwclock --systohc

    # Generating locales.my keys aren't even on
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
