#!/usr/bin/env bash 

set_swap_size() {
    while true; do
        read -r -p "Specify swap file size (in GB) [4]: " swap_size
        # Set default value if swap_size is empty
        swap_size=${swap_size:-4}

        if [[ $swap_size =~ ^[0-9]+$ ]]; then
            swap_size_mb=$(( swap_size * 1024 ))
            echo "Swap file size set to: $swap_size GB ($swap_size_mb MB)"
            break  # Exit the loop once the swap size is set
        else
            echo "Error: Please enter a valid number for swap file size."
        fi
    done
}

read -r -p "Proceed? [Y/n] " response
response=${response:-Y}

set_swap_size  # Call the function to set the swap size
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Proceeding..."
    read -r -p "Specify swapfile location [/.swap/swapfile]: " swap_path
    swap_path=${swap_path:-'/.swap/swapfile'}
    dd if=/dev/zero of="$swap_path" bs=1M count="$swap_size_mb" status=progress
    chmod 0600 "$swap_path"
    mkswap -U clear "$swap_path"
    swapon "$swap_path"
    echo "Swap file created at '$swap_path' and activated."
else
    echo "Exiting..."
    exit 1
fi

