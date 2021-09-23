#!/usr/bin/env bash

sudo apt install zsh fortune-mod figlet git htop neofetch aria2 curl ncdu \
                 python3-pip python3-venv bat p7zip-full ripgrep

# Install Ookla Speedtest
curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
sudo apt install speedtest

# Guard gui dependent applications behind this
echo "Do you intend on using GUI? [y/N]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo rm microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install microsoft-edge-dev code-insiders
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
