#!/usr/bin/env bash

sudo pacman -Sy nvidia nvidia-settings

#Stuff for people with a integrated + dedicated GPU
echo "Do you have Intel integrated GPU and discrete NVIDIA GPU? [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
git clone https://aur.archlinux.org/optimus-manager.git
cd optimus-manager
makepkg -si
cd

#Stuff for optimus-manager to work properly
sudo systemctl enable optimus-manager.service
sudo rm /etc/X11/xorg.conf /etc/X11/xorg.conf.d/90-mhwd.conf
sudo systemctl disable bumblebeed.service
sudo optimus-manager --set-startup intel

#Power saving stuff
sudo su
echo "[optimus]" > /etc/optimus-manager/optimus-manager.conf
echo "switching=none" >> /etc/optimus-manager/optimus-manager.conf 
echo "pci_power_control=no" >> /etc/optimus-manager/optimus-manager.conf
echo "pci_remove=yes" >> /etc/optimus-manager/optimus-manager.conf 
echo "pci_reset=yes" >> /etc/optimus-manager/optimus-manager.conf
fi