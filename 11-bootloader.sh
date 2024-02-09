#!/usr/bin/env bash

echo "Setting up the bootloader..."

EFI_MOUNT_DIR='efi'
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

