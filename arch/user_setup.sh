#!/usr/bin/env bash

set -euo pipefail

git clone https://github.com/gotenksIN/scripts.git

git clone https://aur.archlinux.org/yay-bin.git --depth 1
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin

yay -Sy ookla-speedtest-bin

# Guard gui dependent applications behind this
read -r -e -p "Do you intend on using GUI? [y/N]: " input
if [[ "${input}" =~ ^[Yy]$ ]]; then
        yay -Sy \
                discord \
                gnu-free-fonts \
                gsfonts \
                microsoft-edge-stable-bin \
                noto-fonts \
                noto-fonts-cjk \
                noto-fonts-emoji \
                noto-fonts-extra \
                telegram-desktop \
                ttf-dejavu \
                ttf-droid \
                ttf-liberation \
                ttf-ubuntu-font-family \
                unzip \
                visual-studio-code-bin \
                wezterm-nightly-bin
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
chsh -s /usr/bin/zsh

bash "scripts/common/setup.sh"
