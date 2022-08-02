#!/usr/bin/env -S bash -e

bootctl install

sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/g' /etc/mkinitcpio.conf

mkinitcpio -P

{
    echo "default  arch.conf"
    echo "timeout  4"
    echo "console-mode max"
    echo "editor   no"
} >/boot/efi/loader/loader.conf

{
    echo "title Arch Linux"
    echo "linux /vmlinuz-linux"
    echo "initrd /intel-ucode.img"
    echo "initrd /initramfs-linux.img"
    echo 'options root="LABEL=arch_os" rw'
    echo "options rd.luks.name=c063888b-4066-4fd4-a9ec-47c2b8866c63=crypt rd.luks.options=discard root=/dev/mapper/crypt rw"
} >/boot/efi/loader/entries/arch.conf
