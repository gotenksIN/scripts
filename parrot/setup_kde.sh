#!/bin/bash

sudo apt install parrot-kde sddm 

sudo systemctl enable sddm.service

cp -r -v Dotfiles/.config/* ~/.config/
cp -r -v Dotfiles/.local/* ~/.local/
