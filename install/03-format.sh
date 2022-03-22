# Selecting the cript
PS3="Select cript "
select ENTRY in $(lsblk -pnr | grep -P "crypt" | awk '{ print $1 }');
do
    CRYPT=$ENTRY
    break
done

# Formatting the LUKS Container as BTRFS.
echo "Formatting the LUKS container as BTRFS."
mkfs.btrfs $CRYPT &>/dev/null

read -r -p "Is this single drive system? [Y/n]" response
response=${response,,}
if [[ "$response" =~ ^(no|n)$ ]]; then
    echo "this is multi drive system"
else
    echo "this is single drive system"
fi
