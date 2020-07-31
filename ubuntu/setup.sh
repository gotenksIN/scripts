#!/bin/bash

sudo apt install zsh zsh-autosuggestions fortune-mod figlet git htop cmatrix neofetch aria2 curl ncdu \
                 python3-pip python3-venv zip unzip

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
