#!/usr/bin/env -S bash -e

singleDrive() {
}

# Selecting the cript
PS3="Select cript "
select ENTRY in $(lsblk -pnr | grep -P "crypt" | awk '{ print $1 }');
do
    CRYPT=$ENTRY
    break
done

# Formatting the LUKS Container as BTRFS.
echo "Formatting the LUKS container as BTRFS."
mkfs.btrfs -L "ARCH" $CRYPT &>/dev/null
mount $CRYPT /mnt

echo "Creating BTRFS subvolumes."
btrfs subvolume create /mnt/@

COW_VOLS=(
    boot
    home
    root
    srv
    cryptkey
    var/log
    var/crash
    var/spool
    var/lib/docker
    var/lib/containers
)
NOCOW_VOLS=(
    var/tmp
    var/cache
    var/lib/libvirt/images
    .swap  # If you need Swapfile, create in this folder
)

elem_in() {
    local e m="$1"; shift
    for e in "$@"; do [[ "$m" == "$e" ]] && return 0; done
    return 1
}

for vol in "${COW_VOLS[@]}" "${NOCOW_VOLS[@]}"
do
    btrfs subvolume create "/mnt/@${vol//\//_}"

    if elem_in "$vol" "${NOCOW_VOLS[@]}"; then
        chattr +C "/mnt/@${vol//\//_}"
    fi
done

btrfs subvolume create /mnt/@/.snapshots
mkdir -p /mnt/@/.snapshots/1
btrfs subvolume create /mnt/@/.snapshots/1/snapshot
btrfs subvolume set-default "$(btrfs subvolume list /mnt | grep "@/.snapshots/1/snapshot" | grep -oP '(?<=ID )[0-9]+')" /mnt

cat << EOF >> /mnt/@/.snapshots/1/info.xml
<?xml version="1.0"?>
<snapshot>
    <type>single</type>
    <num>1</num>
    <date>2021-01-01 0:00:00</date>
    <description>First Root Filesystem</description>
    <cleanup>number</cleanup>
</snapshot>
EOF

chmod 600 /mnt/@/.snapshots/1/info.xml

# umount /mnt
