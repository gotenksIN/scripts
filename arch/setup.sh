#!/usr/bin/env bash

sudo pacman -Sy \
        aria2 \
        bat \
        bottom \
        ccache \
        curl \
        fastfetch \
        figlet \
        fortune-mod \
        git \
        htop \
        inetutils \
        keychain \
        ncdu \
        networkmanager \
        ookla-speedtest-bin \
        p7zip \
        python-pip \
        ripgrep \
        schedtool \
        screen \
        wget \
        zsh

sudo systemctl enable NetworkManager.service
sudo systemctl disable NetworkManager-wait-online.service

git clone https://aur.archlinux.org/yay-bin.git --depth 1
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
yay -Sy \
        discord \
        gnu-free-fonts \
        gsfonts \
        microsoft-edge-stable-bin \
        noto-fonts noto-fonts-cjk \
        noto-fonts-emoji \
        noto-fonts-extra \
        telegram-desktop \
        ttf-dejavu \
        ttf-droid \
        ttf-liberation \
        ttf-ubuntu-font-family \
        visual-studio-code-bin \
        wezterm-nightly-bin
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
