#!/usr/bin/env -S bash -e

select_disk() {
    PS3="Select target disk "
    select drive in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd");
    do
        echo "$drive"
	break
    done
}

partition_select() {
    PS3="Please select the system partition:"
    select SYSTEM_PARTITION in $(lsblk -pnoNAME | grep -E "/dev/sd|/dev/nvme|/dev/vd" | sed 's/├─//; s/└─//'); do
	echo "$SYSTEM_PARTITION"
	break
    done
}

select_swap_size() {
    while true; do
        read -r -p "Specify swap file size (in GB) [4]: " swap_size
        # Set default value if swap_size is empty
        swap_size=${swap_size:-4}

        if [[ $swap_size =~ ^[1-9]+$ ]]; then
	    echo "$swap_size"
            break  # Exit the loop once the swap size is set
        else
            echo "Error: Please enter a valid number for swap file size."
        fi
    done
}

make_swap() {
    local swap_path=$1
    local swap_size=$(select_swap_size)  # Call the function to set the swap size
    echo "Swap file size set to: $swap_size GB"

    read -r -p "Proceed? [Y/n] " response
    response=${response:-Y}

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Making swapfile..."
	btrfs filesystem mkswapfile --size "$swap_size"g --uuid clear $swap_path
        swapon "$swap_path"
        echo "Swap file created at '$swap_path' and activated."
    else
	make_swap
    fi
}
