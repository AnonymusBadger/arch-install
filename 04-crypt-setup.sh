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
	--allow-discards \
	--persistent \
	open "$CRYPT" system

