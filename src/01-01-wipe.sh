# Deleting old partition scheme.
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    wipefs -af "$DISK" &>/dev/null
    sgdisk -Zo "$DISK" &>/dev/null
else
    echo "Quitting."
    exit
fi

# Wiping data
read -r -p "Do you wish to write random bytes to the $DISK. [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]; then
    dd if=/dev/urandom of=$DRIVE bs=4M status=progress
fi
