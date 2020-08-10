#!/bin/bash

sudo apt install parrot-kde sddm 

sudo systemctl enable sddm.service

sudo cp -r -v Dotfiles/.config/* ~/.config/
sudo cp -r -v Dotfiles/.local/* ~/.local/
