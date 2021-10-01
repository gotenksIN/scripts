#!/usr/bin/env bash

sudo pacman -Sy nvidia nvidia-utils libvdpau-va-gl

#Stuff for people with a integrated + dedicated GPU
read -e -p "Do you have Intel integrated GPU and discrete NVIDIA GPU? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
yay -Sy system76-power

# Stuff for system76-power to work properly
sudo systemctl enable system76-power.service
sudo systemctl start system76-power.service
sudo system76-power graphics hybrid
fi
