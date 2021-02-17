#!/usr/bin/env bash

# Guard adding Debian Unstable repo
echo "Do you want to add Debian Unstable repo? [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee --append /etc/apt/sources.list
sudo apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
sudo apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
sudo sh -c 'printf "Package: *\nPin: release a=unstable\nPin-Priority: 90\n" > /etc/apt/preferences.d/limit-unstable'
fi

# Guard adding Ookla repo
echo "Do you want to add Ookla repo? [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo apt-get install gnupg1 apt-transport-https dirmngr
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
echo "deb https://ookla.bintray.com/debian generic main" | sudo tee  /etc/apt/sources.list.d/speedtest.list
fi

# Update package list
sudo apt-get update

sudo apt install zsh fortune-mod figlet git htop cmatrix neofetch aria2 curl \
                 ncdu python3-pip python3-venv zip unzip p7zip-full ripgrep

# Install bat only if debian unstable repo exists
if grep -rq "deb http://deb.debian.org/debian/ unstable main" /etc/apt; then
sudo apt install bat
fi

# Install speedtest only if debian unstable repo exists
if grep -rq "deb https://ookla.bintray.com/debian generic main" /etc/apt; then
sudo apt install speedtest
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
