#!/usr/bin/env bash

if [[ "$(command -v apt)" != "" ]]; then
    echo "Debian/Ubuntu Based Distro Detected"
    bash ~/scripts/ubuntu/setup.sh
    cp -r ~/scripts/common/\.* ~/
    echo "source ~/scripts/ubuntu/alias" >> ~/.zshrc
elif [[ "$(command -v pacman)" != "" ]]; then
    echo "Arch Based Distro Detected"
    bash ~/scripts/arch/setup.sh
    cp -r ~/scripts/common/\.* ~/
    echo "source ~/scripts/arch/alias" >> ~/.zshrc
elif [[ "$(command -v dnf)" != "" ]]; then
    echo "Fedora Based Distro Detected"
    bash ~/scripts/fedora/setup.sh
    cp -r ~/scripts/common/\.* ~/
    echo "source ~/scripts/fedora/alias" >> ~/.zshrc
fi

echo "Enable SSH Agent on startup"
systemctl --user enable --now ssh-agent
