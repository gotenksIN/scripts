#!/usr/bin/env bash

# Install signed preloader for uefi and pacman hook to auto-update systemd-boot
yay -Sy systemd-boot-pacman-hook preloader-signed

# Install systemd-boot
sudo bootctl install

# Copy signed preloader to esp
sudo cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi /boot/EFI/systemd

# Setup all vars
export UUID=$(findmnt -kno UUID /)
read -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -e -p "Enter loader name (e.g. vmlinuz-linux): " -i "vmlinuz-linux" loader
read -e -p "Enter initrd name (e.g. initramfs-linux.img): " -i "initramfs-linux.img" initrd
read -e -p "Enter label for uefi entry (Label is what would show up in UEFI entries): " -i "rendumOS" label
read -e -p "Enter label for systemd-boot entry (This is what would show up in systemd-boot options): " -i "rendumOS (fallback)" flabel

# Setup systemd-boot
sudo -s echo "default  arch.conf" > /boot/loader/loader.conf
sudo -s echo "timeout  0" >> /boot/loader/loader.conf
sudo -s echo "console-mode max" >> /boot/loader/loader.conf
sudo -s echo "editor   no" >> /boot/loader/loader.conf

# Setup arch config for systemd-boot
sudo -s echo "title   $flabel" > /boot/loader/entries/arch.conf
sudo -s echo "linux   /$loader" >> /boot/loader/entries/arch.conf
sudo -s echo "initrd  /$initrd" >> /boot/loader/entries/arch.conf

# Microcode setup for arch
read -e -p "Do you have an Intel or AMD CPU? (Y/n): " input
if [[ "$input" =~ ^[Yy]$ ]]; then
read -e -p "Enter 1 for Intel and 2 for AMD: " cpu
if [[ "$cpu" =~ ^[1]$ ]]; then
sudo pacman -Sy intel-ucode
sudo -s echo "initrd  /$microcode" >> /boot/loader/entries/arch.conf
else
sudo pacman -Sy amd-ucode
sudo -s echo "initrd  /$microcode" >> /boot/loader/entries/arch.conf
fi
fi

sudo -s echo "options root=$UUID rw quiet splash" >> /boot/loader/entries/arch.conf

# Create secure-boot compatible entry
sudo efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l EFI/systemd/PreLoader.efi --verbose
