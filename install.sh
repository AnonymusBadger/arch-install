#!/usr/bin/env -S bash -e

# Clean the TTY
clear

# Load localized kayboard layout
loadkeys pl
setfont Lat2-Terminus16.psfu.gz -m 8859-2

# Network config

# Set up system clock
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

### Drive and part creation ###
clear
# Selecting boot drive
fdisk -l
echo

PS3="Select the drive "
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
do
    DRIVE=$ENTRY
    break
done

# Wipe the drive
echo "Wiping the drive"
wipefs -af "$DRIVE" &>/dev/null
sgdisk -Zo "$DRIVE" &>/dev/null
# dd if=/dev/urandom of=$DRIVE bs=4M status=progress

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
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /mnt/etc/pacman.conf
sed -i 's/#Color = 5/Color/g' /mnt/etc/pacman.conf
echo "Installing the base system (it may take a while)."
pacstrap /mnt base linux-zen intel-ucode linux-firmware sof-firmware e2fsprogs grub efibootmgr nvim man-db man-pages texinfo sudo

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
EOF

# Setting root password.
echo "Setting root password."
arch-chroot /mnt /bin/passwd

echo "Unmounting new filesystem"
umount -R /mnt
