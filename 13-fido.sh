#!/usr/bin/env bash

. "./utils.sh"

pacman -S --noconfirm libfido2

systemd-cryptenroll --fido2-device auto $(partition_select)
