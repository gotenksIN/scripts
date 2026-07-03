#!/usr/bin/env bash

sudo dnf upgrade --refresh
sudo dnf install dnf-plugin-system-upgrade
sudo dnf system-upgrade download --releasever=rawhide --allowerasing

read -r -e -p "Reboot into the Rawhide upgrade now? [y/N]: " input
if [[ "${input}" =~ ^[Yy]$ ]]; then
    sudo dnf system-upgrade reboot
fi
