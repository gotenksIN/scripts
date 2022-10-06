#!/usr/bin/env bash

sudo apt install zsh fortune-mod figlet git htop neofetch aria2 curl ncdu \
                 python3-pip python3-venv bat p7zip-full ripgrep schedtool

# Find architecture
arch=`dpkg --print-architecture`
echo "Current system is detected as ${arch} architecture."

# Install Ookla Speedtest
sudo tee /etc/apt/sources.list.d/ookla_speedtest-cli.list > /dev/null <<EOF
deb [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main
deb-src [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/ubuntu/ jammy main
EOF
curl -fsSL https://packagecloud.io/ookla/speedtest-cli/gpgkey | gpg --dearmor | sudo tee /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg > /dev/null
sudo apt update
sudo apt install speedtest

# Install bottom
if [[ $arch = amd64 ]]; then
echo checkpoint
curl -LO https://github.com/ClementTsang/bottom/releases/download/nightly/bottom_x86_64-unknown-linux-gnu.deb
sudo dpkg -i bottom_x86_64-unknown-linux-gnu.deb
rm bottom_x86_64-unknown-linux-gnu.deb
elif [[ $arch = arm64 ]]; then
echo checkpoint
curl -LO https://github.com/ClementTsang/bottom/releases/download/nightly/bottom_aarch64-unknown-linux-gnu.deb
sudo dpkg -i bottom_aarch64-unknown-linux-gnu.deb
rm bottom_aarch64-unknown-linux-gnu.deb
fi

if [[ $arch = amd64 ]]; then
# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo add-apt-repository ppa:font-manager/staging
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo rm microsoft.gpg
sudo tee /etc/apt/sources.list.d/microsoft.list > /dev/null <<EOF
deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main
deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main
EOF
sudo apt update
sudo apt install microsoft-edge-dev code-insiders font-manager
fi
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
