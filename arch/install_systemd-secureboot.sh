#!/usr/bin/env bash

# Install signed preloader for uefi and pacman hook to auto-update systemd-boot
yay -Sy systemd-boot-pacman-hook preloader-signed

# Install systemd-boot
sudo bootctl install

# Copy signed preloader to esp
sudo cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd
sudo cp /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/systemd/loader.efi

# Setup all vars
export UUID=$(findmnt -kno UUID /)
read -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -e -p "Enter loader name (e.g. vmlinuz-linux): " -i "vmlinuz-linux" loader
read -e -p "Enter initrd name (e.g. initramfs-linux.img): " -i "initramfs-linux.img" initrd
read -e -p "Enter label for uefi entry (Label is what would show up in UEFI entries): " -i "rendumOS" label
read -e -p "Enter label for systemd-boot entry (This is what would show up in systemd-boot options): " -i "rendumOS (fallback)" flabel

# Setup systemd-boot
sudo tee /boot/loader/loader.conf > /dev/null <<EOF
default  arch.conf
timeout  0
console-mode max
editor   no
EOF

# Setup arch config for systemd-boot
sudo tee /boot/loader/entries/arch.conf > /dev/null <<EOF
title   $flabel
linux   /$loader
initrd  /$initrd
EOF

# Microcode setup for arch
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
echo "initrd  /$microcode" | sudo tee -a /boot/loader/entries/arch.conf > /dev/null
fi

echo "options root=UUID=$UUID rw quiet splash" | sudo tee -a /boot/loader/entries/arch.conf > /dev/null

# Create secure-boot compatible entry
sudo efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l EFI/systemd/PreLoader.efi --verbose
