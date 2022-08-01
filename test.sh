read -r -p "Secure wipe the drive before install? [y/N]? " response
if [[ "${response,,}" =~ ^(yes|y)$ ]]; then
    echo "if"
else
    echo "else"
fi
