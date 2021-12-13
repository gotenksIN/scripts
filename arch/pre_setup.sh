#!/usr/bin/env bash

# This script assumes you are running in root shell of arch-chroot
# and expected to be ran before setup.sh

# Setup your timezone
read -e -p "Enter your timezone: " -i "Asia/Kolkata" timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Set hostname
read -e -p "Enter your hostname: " hostname
echo"$hostname" > /etc/hostname

# Allow users of group `wheel` to use sudo
echo "%wheel ALL = (ALL) ALL" > /etc/sudoers.d/wheel

# ello mate
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Add muh user
useradd -m -G wheel gotenks
passwd gotenks

# set root password
passwd