#!/usr/bin/env bash

username="kajetan"

su "$username" paru -S --noconfirm shim-signed sbsigntools

openssl req -newkey rsa:2048 \
	-nodes -keyout /etc/refind.d/keys/refind_local.key \
	-new -x509 -sha256 -days 3650 -subj "/CN=my Machine Owner Key/" \
	-out /etc/refind.d/keys/refind_local.crt

openssl x509 -outform DER \
	-in /etc/refind.d/keys/refind_local.crt \
	-out /etc/refind.d/keys/refind_local.cer
