#!/bin/bash

sudo apt install zsh zsh-autosuggestions fortune-mod figlet git htop cmatrix neofetch aria2 curl ncdu \
                 python3-pip python3-venv ffmpeg vlc

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

git config --global user.name "Omkar Chandorkar"
git config --global user.email forumomkar@gmail.com
git config --global user.signingkey 6D8DEF354ED78DE805938A9D95A33FD984777F70
git config --global gpg.program gpg
git config --global commit.gpgsign true
git config --global pull.rebase false
git config --global core.editor nano
