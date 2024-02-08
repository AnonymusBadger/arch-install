#!/usr/bin/env bash 

EFI_MOUNT_DIR="/boot"
CONF_DIR="$EFI_MOUNT_DIR/EFI/refind"
BACKUP_CONF_PATH="$CONF_DIR/refind.conf.bak"

# Install rEFInd and drivers
pacman -S --needed refind
refind-install

# Backup existing configuration
if [[ -f "$CONF_DIR/refind.conf" ]]; then
    mv "$CONF_DIR/refind.conf" "$BACKUP_CONF_PATH"
    echo "Backup of existing refind.conf created at: $BACKUP_CONF_PATH"
fi

if [[ -f "$EFI_MOUNT_DIR/refind_linux.conf" ]]; then
    mv "$EFI_MOUNT_DIR/refind_linux.conf" "$EFI_MOUNT_DIR/refind_linux.conf.bak"
    echo "Backup of existing refind_linux.conf created at: $EFI_MOUNT_DIR"
fi

# Install drivers
mkdir -p "$CONF_DIR/drivers_x64"
DRIVER="btrfs_x64.efi"
DRIVER_INSTALL_PATH="$CONF_DIR/drivers_x64/$DRIVER"
cp "/usr/share/refind/drivers_x64/$DRIVER" "$DRIVER_INSTALL_PATH"

# Prompt user to select system partition
echo "Please select the system partition:"
select SYSTEM_PARTITION in $(lsblk -pnoNAME | grep -E "/dev/sd|/dev/nvme|/dev/vd" | sed 's/├─//; s/└─//'); do
    DRIVE_PART_UUID="$(blkid "$SYSTEM_PARTITION" | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')"
    break
done

# Generate rEFInd configuration
cat > "$CONF_DIR/refind.conf" <<EOF
timeout         5
also_scan_dirs  +,@root/
resolution      1920 1200
enable_touch
enable_mouse
EOF

# Generate refind_linux.conf
cat > "/boot/refind_linux.conf" <<EOF
"Boot with standard options"  "rd.luks.name=$DRIVE_PART_UUID=system root=/dev/mapper/system rootflags=subvol=@root initrd=/intel-ucode.img initrd=/initramfs-linux-zen.img"
"Boot with fallback initramfs"  "rd.luks.name=$DRIVE_PART_UUID=system root=/dev/mapper/system rootflags=subvol=@root initrd=/intel-ucode.img initrd=/initramfs-linux-zen.img"
EOF

echo "rEFInd setup completed successfully."
