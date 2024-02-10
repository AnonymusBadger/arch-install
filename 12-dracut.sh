#!/usr/bin/env bash

. "./utils.sh"

echo "Setting up dracut..."
SYSTEM_PARTITION=$(partition_select)
SYSTEM_PART_UUID="$(blkid "$SYSTEM_PARTITION" | cut -d " " -f2 | cut -d '=' -f2 | sed 's/\"//g')"

cat > /etc/dracut.conf.d/00-options.conf <<EOF
hostonly="yes"
hostonly_cmdline="no"
early_microcode="yes"
compress="lz4"
add_dracutmodules+=" systemd fido2 "
uefi="yes"
machine_id="no"
parallel="yes"
uefi_splash_image="/usr/share/systemd/bootctl/splash-arch.bmp"
EOF

cat > /etc/dracut.conf.d/10-cmdline.conf <<EOF
kernel_cmdline="rd.luks.allow-discards rd.luks.options=discard,fido2-device=auto rd.luks.name=$SYSTEM_PART_UUID=cryptroot root=/dev/mapper/cryptroot rootfstype=btrfs rootflags=subvol=@root quiet "
EOF

cat > /etc/dracut.conf.d/20-secureboot.conf <<EOF
uefi_secureboot_cert="/etc/refind.d/keys/refind_local.crt"
uefi_secureboot_key="/etc/refind.d/keys/refind_local.key"
EOF

username=kajetan
sudo -u "$username" paru -S --noconfirm dracut-uefi-hook
