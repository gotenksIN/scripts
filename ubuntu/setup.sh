#!/usr/bin/env bash

sudo apt install nala

sudo nala install zsh fortune-mod figlet git htop aria2 curl ncdu \
                 python3-pip python3-venv bat 7zip ripgrep schedtool keychain

# Find architecture
arch=`dpkg --print-architecture`
echo "Current system is detected as ${arch} architecture."

# Install Ookla Speedtest
sudo tee /etc/apt/sources.list.d/ookla_speedtest-cli.list > /dev/null <<EOF
deb [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main
deb-src [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main
EOF
curl -fsSL https://packagecloud.io/ookla/speedtest-cli/gpgkey | gpg --dearmor | sudo tee /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg > /dev/null
sudo nala update
sudo nala install speedtest

# Install bottom
if [[ $arch = amd64 ]]; then
curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb
sudo dpkg -i bottom_0.9.6_amd64.deb
rm bottom_0.9.6_amd64.deb
elif [[ $arch = arm64 ]]; then
curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_arm64.deb
sudo dpkg -i bottom_0.9.6_arm64.deb
rm bottom_0.9.6_arm64.deb
fi

# Install fastfetch
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo nala install fastfetch

if [[ $arch = amd64 ]]; then
# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo rm packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/edge/ stable main" > /etc/apt/sources.list.d/microsoft-edge.list'
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo nala update
sudo nala install microsoft-edge-stable code font-manager flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.telegram.desktop
fi
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
