#!/bin/bash

# set timedate
timedatectl set-ntp true
timedatectl set-timezome Europe/Warsaw

pacman -Syu
