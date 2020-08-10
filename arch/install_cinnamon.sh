#!/usr/bin/env bash

#Install all packages required for cinnamon to work nicely
sudo pacman -Sy xorg-server cinnamon gnome-terminal gnome-screenshot lightdm eog nemo-fileroller rhythmbox gedit evince
sudo localectl set-locale LANG=en_US.UTF-8
sudo locale-gen

#Setup lightdm along with slick-greeter plus necessary configs
git clone https://aur.archlinux.org/lightdm-slick-greeter
cd lightdm-slick-greeter
makepkg -si
cd
sudo su
sed -i "s/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/" /etc/lightdm/lightdm.conf
exit

#Install packages related to bluetooth as needed
echo "Do you have any bluetooth adaptors installed? [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo pacman -Sy blueberry
sudo systemctl enable bluetooth.service
fi

#Enable some services for convenience
sudo systemctl enable NetworkManager.service
sudo systemctl disable NetworkManager-wait-online.service
systemctl enable lightdm.service
