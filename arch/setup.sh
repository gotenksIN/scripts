#!/usr/bin/env bash

sudo pacman -Sy git base-devel fortune-mod figlet zsh htop ncdu nano bottom \
                wget curl aria2 inetutils bat ripgrep p7zip efibootmgr neofetch \
                screen ccache

git clone https://aur.archlinux.org/yay.git --depth 1
cd yay
makepkg -si
cd ..
rm -rf yay

yay -Sy ookla-speedtest-bin

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
yay -Sy microsoft-edge-dev-bin kotatogram-desktop-bin vlc \
        visual-studio-code-insiders-bin ttf-dejavu ttf-droid \
        gnu-free-fonts ttf-liberation noto-fonts noto-fonts-cjk \
        noto-fonts-emoji noto-fonts-extra ttf-ubuntu-font-family \
        gsfonts qbittorrent discord spotify
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
