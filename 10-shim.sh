#!/usr/bin/env bash

username="kajetan"

sudo -U "$username" paru -S --noconfirm shim-signed sbsigntools

mkdir -p /etc/refind.d/keys
chmod 700 /etc/refind.d/keys
openssl req -newkey rsa:2048 \
	-nodes -keyout /etc/refind.d/keys/refind_local.key \
	-new -x509 -sha256 -days 3650 -subj "/CN=my Machine Owner Key/" \
	-out /etc/refind.d/keys/refind_local.crt

openssl x509 -outform DER \
	-in /etc/refind.d/keys/refind_local.crt \
	-out /etc/refind.d/keys/refind_local.cer
