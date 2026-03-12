#!/usr/bin/env bash

# This script assumes you are running in root shell of archiso
# and expected to be ran before chroot.sh

read -r -e -p "Enter boot partition device: " -i "/dev/sda1" boot_part
read -r -e -p "Enter swap partition device: " -i "/dev/sda2" swap_part
read -r -e -p "Enter root partition device: " -i "/dev/sda3" root_part
read -r -e -p "Enter home partition device (leave blank to skip): " home_part
read -r -e -p "Enter packages for pacstrap: " -i "base base-devel linux linux-firmware sudo efibootmgr nano git f2fs-tools" pacstrap_package_line

mount "${root_part}" /mnt

if [[ -n "${home_part}" ]]; then
        mount --mkdir "${home_part}" /mnt/home
fi

mount --mkdir "${boot_part}" /mnt/boot
swapon "${swap_part}"

read -r -a pacstrap_packages <<< "${pacstrap_package_line}"
pacstrap -K /mnt "${pacstrap_packages[@]}"
genfstab -U /mnt > /mnt/etc/fstab

echo "Base system installed. Next: arch-chroot /mnt and run chroot.sh"
