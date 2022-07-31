# Selecting the disk
PS3="Select the disk "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    break
done
