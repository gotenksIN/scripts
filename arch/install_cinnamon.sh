#!/usr/bin/env bash

# Install all packages required for cinnamon to work nicely
paru -Sy xorg-server cinnamon gnome-screenshot lightdm lightdm-slick-greeter nemo-fileroller gnome-keyring pipewire pipewire-pulse papirus-icon-theme arc-gtk-theme dconf-editor

# Setup lightdm along with slick-greeter plus necessary configs
sudo sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/" /etc/lightdm/lightdm.conf

# Install packages related to bluetooth if needed
read -e -p "Do you have any bluetooth adaptors installed? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo pacman -Sy bluez bluez-utils blueman
sudo systemctl enable bluetooth.service
fi

# Enable some services for convenience
sudo systemctl enable lightdm.service
