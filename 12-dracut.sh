#!/usr/bin/env bash

. "./utils.sh"

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
