#!/bin/bash

# set timedate
timedatectl set-ntp true
timedatectl set-timezone Europe/Warsaw

pacman -Syu
