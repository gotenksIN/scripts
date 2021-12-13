#!/usr/bin/env bash

# This script assumes you are running in root shell of arch-chroot
# and expected to be ran before setup.sh

# Setup your timezone
read -e -p "Enter your timezone: " -i "Asia/Kolkata" timezone
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc

# Set hostname
read -e -p "Enter your hostname: " hostname
echo "$hostname" > /etc/hostname

# Allow users of group `wheel` to use sudo
echo "%wheel ALL = (ALL) ALL" > /etc/sudoers.d/wheel

# ello mate
sed -i 's/^# en_GB\.U/en_GB\.U/' /etc/locale.gen
sed -i 's/^# en_US\.U/en_US\.U/' /etc/locale.gen
localectl set-locale LANG=en_GB.UTF-8
locale-gen

# Add muh user
read -e -p "Enter your username: " -i "gotenks" username
useradd -m -G wheel $username
passwd $username

# set root password
passwd
