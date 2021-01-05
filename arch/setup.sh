#!/usr/bin/env bash

sudo pacman -Sy ffmpeg fortune-mod figlet zsh htop git cmatrix ncdu nano base-devel

git clone https://aur.archlinux.org/yay.git --depth 1
cd yay
makepkg -si
cd ..
rm -rf yay

# Guard gui dependent applications behind this
echo "Do you intend on using GUI? [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
yay -Sy microsoft-edge-dev-bin kotatogram-desktop-bin visual-studio-code-insiders-bin vlc steam 
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
