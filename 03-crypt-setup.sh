#!/usr/bin/env bash

CRYPT_LABEL="cryptroot"
SYSTEM_LABEL="cryptroot"

CRYPT="/dev/disk/by-partlabel/$CRYPT_LABEL"

echo "Creating a new crypt..."
cryptsetup luksFormat \
	--perf-no_read_workqueue \
	--perf-no_write_workqueue \
	--type luks2 \
	--cipher twofish-xts-plain64 \
	--key-size 512 \
	--iter-time 5000 \
	--align-payload=8192 \
	--hash sha512 \
	"$CRYPT"

echo "Crypt created! Opening..."
cryptsetup \
	--perf-no_read_workqueue \
	--perf-no_write_workqueue \
	--allow-discards \
	--persistent \
	open "$CRYPT" "$SYSTEM_LABEL"
