#!/usr/bin/env bash

# Guard adding Ookla repo
echo "Do you want to add Ookla repo? [y/N]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo apt-get install gnupg1 apt-transport-https dirmngr
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
echo "deb https://ookla.bintray.com/debian generic main" | sudo tee  /etc/apt/sources.list.d/speedtest.list
fi

# Guard gui dependent applications behind this
echo "Do you intend on using GUI? [y/N]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo rm microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt install microsoft-edge-dev code-insiders
fi

# Update package list
sudo apt-get update

sudo apt install zsh fortune-mod figlet git htop cmatrix neofetch aria2 curl ncdu \
                 python3-pip python3-venv zip unzip bat p7zip-full ripgrep

# Install speedtest only if Ookla repo exists
if grep -rq "deb https://ookla.bintray.com/debian generic main" /etc/apt; then
sudo apt install speedtest
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
