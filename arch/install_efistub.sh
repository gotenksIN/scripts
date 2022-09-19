#!/usr/bin/env bash

read -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -e -p "Enter loader name (e.g. vmlinuz-linux): " -i "vmlinuz-linux" loader
read -e -p "Enter initrd name (e.g. initramfs-linux.img): " -i "initramfs-linux.img" initrd
read -e -p "Enter label for this entry (Label is what would show up in UEFI entries): " -i "rendumOS (efistub)" label
read -e -p "Enter any extra arguments you want to pass to kernel cmdline: " extra

read -e -p "Do you have an Intel or AMD CPU? (Y/n): " input
if [[ "$input" =~ ^[Yy]$ ]]; then
read -e -p "Enter 1 for Intel and 2 for AMD: " cpu
if [[ "$cpu" =~ ^[1]$ ]]; then
sudo pacman -Sy intel-ucode
microcode="intel-ucode.img"
else
sudo pacman -Sy amd-ucode
microcode="amd-ucode.img"
fi
printf -v largs "%s " \
        "root=UUID=$(findmnt -kno UUID /) rw" \
        "initrd"=${microcode} "initrd=${initrd}" \
        quiet splash

else
printf -v largs "%s " \
        "root=UUID=$(findmnt -kno UUID /) rw" \
        "initrd=${initrd}" quiet splash
fi

sudo efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l "${loader}" -u "${largs%* } ${extra}" --verbose
