#!/usr/bin/env bash 

EFI_MOUNT_DIR="/efi"
CONF_DIR="$EFI_MOUNT_DIR/EFI/refind"

pacman -S refind-efi
refind-install 

# install drivers
mkdir -p $CONF_DIR/drivers_x64
DRIVER=btrfs_x64.efi
DRIVER_INSTALL_PATH=$CONF_DIR/drivers_x64/$DRIVER
cp /usr/share/refind/drivers_x64/$DRIVER $DRIVER_INSTALL_PATH

exit

# theme setup
THEME_NAME=refind-theme-regular
if [ ! -d "$CONF_DIR/themes/$THEME_NAME" ]; then
  mkdir -p $CONF_DIR/themes
  run_in_system "git clone https://github.com/bobafetthotmail/refind-theme-regular.git /boot/EFI/refind/themes/$THEME_NAME"
  rm -rf $CONF_DIR/themes/$THEME_NAME/{src,.git}
  rm $CONF_DIR/themes/$THEME_NAME/install.sh
fi

BACKUP_CONF_PATH="$CONF_DIR/refind.conf.bak"
if [ ! -f "$BACKUP_CONF_PATH" ]; then
  mv $CONF_DIR/refind.conf $BACKUP_CONF_PATH
fi

echo "Please select the system partition:"
select SYSTEM_PARTITION  in $(lsblk -pnoNAME | grep -E "/dev/sd|/dev/nvme|/dev/vd" | sed 's/├─//; s/└─//');
do
    echo "$drive"
    break
done

DRIVE_PART_UUID="$(blkid $SYSTEM_PARTITION | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')"
cat > $CONF_DIR/refind.conf <<EOF
menuentry "Arch Linux" {
    icon     /EFI/refind/themes/$THEME_NAME/icons/128-48/os_arch.png
    volume   "Arch Linux"
    loader   /vmlinuz-linux
    initrd   /initramfs-linux-zen.img
    options  "rd.luks.name=$DRIVE_PART_UUID=system root=/dev/mapper/system rootflags=subvol=@root rw quiet nmi_watchdog=0 add_efi_memmap initrd=/intel-ucode.img"
    submenuentry "Boot using fallback initramfs" {
        initrd /boot/initramfs-linux-zen-fallback.img
    }
}
timeout         5
include         themes/$THEME_NAME/theme.conf
also_scan_dirs  +,@root/
resolution 	1920 1200
EOF

cat $CONF_DIR/refind.conf
