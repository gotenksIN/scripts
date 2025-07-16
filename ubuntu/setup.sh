#!/usr/bin/env bash

sudo apt install nala

sudo nala install zsh fortune-mod figlet git htop aria2 curl ncdu \
                 python3-pip python3-venv bat 7zip ripgrep schedtool keychain

# Find architecture
arch=`dpkg --print-architecture`
echo "Current system is detected as ${arch} architecture."

# Install Ookla Speedtest
sudo tee /etc/apt/sources.list.d/ookla_speedtest-cli.sources > /dev/null <<EOF
Types: deb
URIs: https://packagecloud.io/ookla/speedtest-cli/ubuntu/
Suites: jammy
Components: main
Signed-By: /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg
EOF
curl -fsSL https://packagecloud.io/ookla/speedtest-cli/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/ookla_speedtest-cli-archive-keyring.gpg > /dev/null
sudo nala update
sudo nala install speedtest

# Install bottom
if [[ $arch = amd64 ]]; then
sudo nala install https://github.com/ClementTsang/bottom/releases/download/0.10.2/bottom_0.10.2-1_amd64.deb
elif [[ $arch = arm64 ]]; then
sudo nala install https://github.com/ClementTsang/bottom/releases/download/0.10.2/bottom_0.10.2-1_arm64.deb
fi

# Install fastfetch
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo nala install fastfetch

if [[ $arch = amd64 ]]; then
# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/microsoft.gpg
sudo rm packages.microsoft.gpg
sudo tee /etc/apt/sources.list.d/microsoft-edge.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/edge
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
sudo nala update
sudo nala install microsoft-edge-stable code font-manager flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.telegram.desktop
fi
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
