#!/usr/bin/env bash

#Add kernel and initramfs to your boot partition

sudo touch /etc/kernel/postinst.d/zz-update-efistub
echo '#!/bin/sh' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
echo 'cp /boot/vmlinuz /boot/initrd.img /boot/efi/EFI/ubuntu/' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
sudo chmod +x /etc/kernel/postinst.d/zz-update-efistub
sudo /etc/kernel/postinst.d/zz-update-efistub

loader='\EFI\ubuntu\vmlinuz'
initrd='\EFI\ubuntu\initrd.img'

read -r -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -r -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -r -e -p "Enter label for this entry (Label is what would show up in UEFI entries): " -i "ubuntu (efistub)" label
read -r -e -p "Enter any extra arguments you want to pass to kernel cmdline: " extra

printf -v largs "%s " \
        "root=UUID=$(findmnt -kno UUID /) rw" \
        "initrd=${initrd}"

sudo efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l "${loader}" -u "${largs%* } quiet splash ${extra}" --verbose
