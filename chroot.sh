#!/usr/bin/env bash

. ./utils.sh

echo "Set root password"
passwd
echo "Updating pacman..."
pacman -Syy --noconfirm

echo 'KEYMAP=pl' > /etc/vconsole.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# locale =================================================================================
echo "Setting locale..."
sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen
sed -i '/^# *pl_PL.UTF-8/s/^# *//' /etc/locale.gen
locale-gen

echo "Setting Time and Date..."
# Time and Date ==========================================================================
ln -sf "/usr/share/zoneinfo/Europe/Warsaw" /etc/localtime
hwclock --systohc

systemctl enable systemd-timesyncd.service

# Hostname ===============================================================================
echo "Setting Hostname..."
read -r -p "Please enter name system hostname: " hostname
echo "$hostname" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	${hostname}
EOF

# Network ================================================================================
echo "Setting up NetworkManager..."
pacman -S --noconfirm networkmanager iwd

backend_conf_file='/etc/NetworkManager/conf.d/wifi_backend.conf'
cat > $backend_conf_file <<EOF
[device]
wifi.backend=iwd
EOF

systemctl enable NetworkManager.service

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

# Seting up the shim
openssl req -newkey rsa:2048 \
	-nodes -keyout /etc/refind.d/keys/refind_local.key \
	-new -x509 -sha256 -days 3650 -subj "/CN=my Machine Owner Key/" \
	-out /etc/refind.d/keys/refind_local.crt

openssl x509 -outform DER \
	-in /etc/refind.d/keys/refind_local.crt \
	-out /etc/refind.d/keys/refind_local.cer


echo "Installing Paru..."
git clone https://aur.archlinux.org/paru.git
cd paru
su "$username" -c makepkg -sic
cd /
rm -rf ./paru
su "$username" paru -S --noconfirm shim-signed sbsigntools
exit

# Bootloader =============================================================================
echo "Setting up the bootloader..."

CONF_DIR="/$EFI_MOUNT_DIR/EFI/refind"
BACKUP_CONF_PATH="$CONF_DIR/refind.conf.bak"
pacman -S --noconfirm --needed refind
refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys

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

# Setup dracut ===========================================================================
echo "Setting up dracut..."
SYSTEM_PARTITION=$(partition_select)
SYSTEM_PART_UUID="$(blkid "$SYSTEM_PARTITION" | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')"

cat > /etc/dracut.conf.d/00-options.conf <<EOF
hostonly="yes"
hostonly_cmdline="no"
early_microcode="yes"
compress="zstd"
add_dracutmodules+=" systemd "
uefi="yes"
EOF

cat > /etc/dracut.conf.d/10-cmdline.conf <<EOF
kernel_cmdline="rd.luks.name=$SYSTEM_PART_UUID=cryptroot root=/dev/mapper/cryptroot rootfstype=btrfs rootflags=subvol=@root"
EOF

cat > /etc/dracut.conf.d/20-secureboot.conf <<EOF
uefi_secureboot_cert="/etc/refind.d/keys/refind_local.crt"
uefi_secureboot_key="/etc/refind.d/keys/refind_local.key"
EOF

su "$username" paru -S --noconfirm dracut-ukify
