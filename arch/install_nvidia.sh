#!/usr/bin/env bash

read -e -p "Are you using any custom kernel? [Y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo pacman -Sy nvidia-dkms nvidia-utils nvidia-settings libvdpau-va-gl
else
sudo pacman -Sy nvidia nvidia-utils nvidia-settings libvdpau-va-gl
fi

#Stuff for people with a integrated + dedicated GPU
read -e -p "Do you have Intel integrated GPU and discrete NVIDIA GPU? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
yay -Sy system76-power

# Stuff for system76-power to work properly
sudo systemctl enable system76-power.service
sudo systemctl start system76-power.service
sudo system76-power graphics hybrid
fi
