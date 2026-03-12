#!/usr/bin/env bash

# This script assumes you are running in root shell of arch-chroot
# and expected to be ran before setup.sh

# Setup your timezone
read -r -e -p "Enter your timezone: " -i "Asia/Kolkata" timezone
timezone_path="/usr/share/zoneinfo/${timezone}"
if [[ ! -e "${timezone_path}" ]]; then
        echo "Invalid timezone: ${timezone}"
        exit 1
fi
ln -sf "${timezone_path}" /etc/localtime
hwclock --systohc

# Set hostname
read -r -e -p "Enter your hostname: " hostname
printf '%s\n' "${hostname}" > /etc/hostname

# Allow users of group `wheel` to use sudo
printf '%%wheel ALL = (ALL) ALL\n' > /etc/sudoers.d/wheel

# ello mate
sed -i -E 's/^#\s*(en_GB\.UTF-8 UTF-8)/\1/' /etc/locale.gen
sed -i -E 's/^#\s*(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen
sed -i -E 's/^#\s*(en_IN\.UTF-8 UTF-8)/\1/' /etc/locale.gen
printf 'LANG=en_GB.UTF-8\n' > /etc/locale.conf
locale-gen

sed -i -E '/^HOOKS=/ {
        /\<plymouth\>/b done
        /\<systemd\>/ s/\<systemd\>/systemd plymouth/
        /\<systemd\>/! s/\<filesystems\>/plymouth filesystems/
        :done
}' /etc/mkinitcpio.conf
mkinitcpio -P

# Add muh user
read -r -e -p "Enter your username: " -i "gotenks" username
useradd -m -G wheel "${username}"
echo "Set password for ${username}"
passwd "${username}"

# set root password
echo "Set root password"
passwd

# Disable pcspkr
printf 'blacklist pcspkr\n' > /etc/modprobe.d/nobeep.conf
