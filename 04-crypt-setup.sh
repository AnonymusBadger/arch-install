#!/usr/bin/env bash 

CRYPT="/dev/disk/by-partlabel/crypt"

echo "Creating a new crypt"
cryptsetup luksFormat \
	--type luks2 \
	--cipher twofish-xts-plain64 \
	--key-size 512 \
	--iter-time 5000 \
	--align-payload=8192 \
	--hash sha512 \
	"$CRYPT"

echo "Crypt created, opening"
cryptsetup \
	--perf-no_read_workqueue \
	--perf-no_write_workqueue \
	--allow-discards \
	--persistent \
	open "$CRYPT" system

