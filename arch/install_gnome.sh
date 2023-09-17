#!/usr/bin/env bash

# Install bare minimum packages required for GNOME to work like I want to
yay -Sy gdm gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-shell-extension-tiling-assistant gnome-shell-extension-ubuntu-dock gnome-tweaks gvfs nautilus

# Fix file explorer association
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Enable GDM
sudo systemctl enable gdm.service
