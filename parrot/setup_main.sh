#!/bin/bash


sudo apt install zsh zsh-autosuggestions figlet git htop cmatrix neofetch curl python3-pip python3-venv codium vscodium
sudo rm -rf /var/cache/snapd/
sudo apt autoremove --purge snapd apparmor ^avahi rsyslog apport ^vim
rm -rf ~/snap

#install oh-my-zsh and powerlevel10k
chsh -s /usr/bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

#update zshrc
sudo cp Dotfiles/.zshrc ~/

#install spotify
curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client
