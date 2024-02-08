#!/usr/bin/env bash

# script setup
exec_dir=$(realpath "$(dirname "${BASH_SOURCE[0]}")")
. "$exec_dir/utils.sh"

# config ====================================================================================
timezone='Europe/Warsaw'
keymap='pl'
locales=( 'en_US.UTF-8' 'pl_PL.UTF-8' )

# Live image setup ==========================================================================
loadkeys $keymap

# configure pacman
sed -i '/^#Color/s/^#//' /etc/pacman.conf
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sed -i '/^#Include = \/etc\/pacman\.d\/mirrorlist/s/^#//' /etc/pacman.conf

# Sync time =================================================================================
echo "Setting date and time..."
timedatectl set-timezone "$timezone"
timedatectl set-ntp true

# Format drive ==============================================================================
DISK=$(select_disk)
echo "Formating the drive..."
ESP_LABEL="EFI"
PRIMARY_LABEL="crypt"

sgdisk --zap-all $DRIVE

parted -s "$DISK" \
    mklabel gpt \
    mkpart "$ESP_LABEL" fat32 1MiB "1025MiB" \
    set 1 esp on \
    mkpart "$PRIMARY_LABEL" "1025MiB" 100%

partprobe "$DISK"
sleep 1 # Sleep to changes to register


# Crypt setup ================================================================================
CRYPT="/dev/disk/by-partlabel/crypt"
MAP_NAME="system"

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
	open "$CRYPT" "$MAP_NAME"

# Partitioning ===============================================================================
echo "Partitioning..."
mkfs.fat -F32 -n "$ESP_LABEL" "/dev/disk/by-partlabel/$ESP_LABEL"

mkfs.btrfs --force --label "$MAP_NAME" "/dev/mapper/$MAP_NAME"

mount -t btrfs LABEL="$MAP_NAME" /mnt
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
    local mount_options="defaults,x-mount.mkdir,discard=async,ssd,noatime,compress=zstd:1"
    mount -t btrfs -o subvol="$subvol",$mount_options LABEL="$MAP_NAME" "$mount_point"
}

# Mount Btrfs subvolumes
mount_btrfs "@root" /mnt
mount_btrfs "@home" /mnt/home
mount_btrfs "@snapshots" /mnt/.snapshots
mount_btrfs "@swap" /mnt/.swap

#mount efi
EFI_MOUNT_DIR="efi"
mkdir -p "/mnt/$EFI_MOUNT_DIR"
mount LABEL="$ESP_LABEL" "/mnt/$EFI_MOUNT_DIR"

# Make swap
echo "Creating swapfile..."
chattr +C /mnt/.swap
make_swap /mnt/.swap/swapfile

# Pacstrap ===================================================================================
echo "Base install..."
pacstrap -P /mnt \
	base \
       	base-devel \
       	linux-zen \
       	linux-firmware \
	linux-headers \
       	intel-ucode \
	btrfs-progs \
       	neovim \
       	man-db \
       	man-pages \
       	texinfo \
       	sudo \
	btrfs-progs \
	dracut \
	git

genfstab -L -p /mnt >> /mnt/etc/fstab

# Fix cow settings
chattr +C /mnt/tmp
chattr +C /mnt/var

# Chroot exec ================================================================================
chroot() {
    echo "Set root password"
    passwd
    echo "Updating pacman..."
    pacman -Syy --noconfirm
    echo 'KEYMAP=pl' > /etc/vconsole.conf

    # locale =================================================================================
    echo "Setting locale..."
    sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen
    sed -i '/^# *pl_PL.UTF-8/s/^# *//' /etc/locale.gen
    locale-gen
    localectl set-locale LANG=en_US.UTF-8

    echo "Setting Time and Date..."
    # Time and Date ==========================================================================
    timedatectl set-ntp 1
    timedatectl set-timezone Europe/Warsaw
    systemctl enable systemd-timesyncd.service
    hwclock --systohc


    # Hostname ===============================================================================
    echo "Setting Hostname..."
    read -r -p "Please enter name system hostname: " hostname
    hostnamectl set-hostname "$hostname"
    cat >> /etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	${hostname}
EOF

    # Network ================================================================================
    echo "Setting up NetworkManager..."
    pacman -S --noconfirm networkmanager iwd

    backend_conf_file='/etc/NetworkManager/conf.d/wifi_backend.conf'
    cat >> $backend_conf_file <<EOF
[device]
wifi.backend=iwd
EOF

    systemctl enable NetworkManager.service


    # Bootloader =============================================================================
    echo "Setting up the bootloader..."

    CONF_DIR="/$EFI_MOUNT_DIR/EFI/refind"
    BACKUP_CONF_PATH="$CONF_DIR/refind.conf.bak"
    pacman -S --needed refind | yes
    refind-install

    # Backup existing configuration
    if [[ -f "$CONF_DIR/refind.conf" ]]; then
	mv "$CONF_DIR/refind.conf" "$BACKUP_CONF_PATH"
	echo "Backup of existing refind.conf created at: $BACKUP_CONF_PATH"
    fi

    # Generate rEFInd configuration
    cat > "$CONF_DIR/refind.conf" <<EOF
timeout         5
resolution      1920 1200
enable_touch
enable_mouse
EOF

    # Install drivers
    mkdir -p "$CONF_DIR/drivers_x64"
    DRIVER="btrfs_x64.efi"
    DRIVER_INSTALL_PATH="$CONF_DIR/drivers_x64/$DRIVER"
    cp "/usr/share/refind/drivers_x64/$DRIVER" "$DRIVER_INSTALL_PATH"

    # Setup dracut ===========================================================================
    echo "Removing mkinicpio..."
    pacman --noconfirm -Runs mkinitcpio

    echo "Setting up dracut..."
    SYSTEM_PARTITION=$(partition_select)
    SYSTEM_PART_UUID="$(blkid "$SYSTEM_PARTITION" | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')"

    cat >> /etc/dracut.conf.d/00-options.conf <<EOF
hostonly="yes"
hostonly_cmdline="no"
early_microcode="yes"
compress="zstd"
reproducible="yes"
add_dracutmodules+=" systemd "
uefi="yes"
kernel_cmdline="rd.luks.name=$SYSTEM_PART_UUID=$MAP_NAME root=/dev/mapper/$MAP_NAME rootfstype=btrfs rootflags=subvol=@root"
EOF
    dracut --force

    # Userspace ==============================================================================

    # Setup sudo
    echo "Creatign a new user..."
    echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel
    read -r -p "Please enter name for a user account: " username
    echo "Adding $username with root privilege."
    useradd -m $username
    usermod -aG wheel $username 
    # usermod --shell /bin/zsh $username 
    passwd "$username"

    echo "Installing arch-install scripts" 
    git clone --depth=1 https://github.com/AnonymusBadger/arch-install.git "/home/$username/arch-install"
}

arch-chroot /mnt chroot
