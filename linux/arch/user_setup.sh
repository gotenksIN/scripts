#!/usr/bin/env bash

set -euo pipefail

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
                vlc \
                vlc-plugins-all \
                wezterm-nightly-bin
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$repo_dir/linux/common/setup.sh" arch
