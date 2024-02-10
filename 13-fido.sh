#!/usr/bin/env bash

. "./utils.sh"

pacman -S --noconfirm libfido

systemd-cryptenroll --fido2-device auto $(partition_select)
