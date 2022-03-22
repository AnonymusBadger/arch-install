# Selecting the cript
PS3="Select cript "
select ENTRY in $(lsblk -pnr | grep -P "crypt" | awk '{ print $1 }');
do
    CRYPT=$ENTRY
    break
done
