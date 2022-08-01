#!/usr/bin/env -S bash -e

# Create new user.
read -r -p "Please enter name for a user account: " username
arch-chroot /mnt /bin/bash -e <<EOF
    echo "Adding $username with root privilege."
    useradd -m $username
    usermod -aG wheel $username
    usermod --shell /bin/zsh $username

    echo "Installing arch-install scripts"
    git clone --depth=1 https://github.com/AnonymusBadger/arch-install.git ~$username/arch-install
EOF

# Setting root password.
echo "Setting root password."
arch-chroot /mnt /bin/passwd

echo "Setting password for $username."
arch-chroot /mnt /bin/passwd "$username"
