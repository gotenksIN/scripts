#!/usr/bin/env bash

# Install bare minimum packages required for Plasma
yay -Sy plasma-meta dolphin

# Enable Plasma Login Manager
sudo systemctl enable plasmalogin.service
