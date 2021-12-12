#!/usr/bin/env bash

sudo apt install zsh fortune-mod figlet git htop neofetch aria2 curl ncdu \
                 python3-pip python3-venv bat p7zip-full ripgrep

# Install Ookla Speedtest
wget https://install.speedtest.net/app/cli/install.deb.sh
chmod +x install.deb.sh
sudo os=ubuntu dist=hirsute ./install.deb.sh
rm install.deb.sh
sudo apt install speedtest

# Install bottom
curl -LO https://github.com/ClementTsang/bottom/releases/download/0.6.4/bottom_0.6.4_amd64.deb
sudo dpkg -i bottom_0.6.4_amd64.deb
rm bottom_0.6.4_amd64.deb

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo add-apt-repository ppa:font-manager/staging
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo rm microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install microsoft-edge-dev code-insiders font-manager telegram-desktop
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
