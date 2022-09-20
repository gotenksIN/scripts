#!/usr/bin/env bash

# Enable RPM Fusion repositories
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install frequently used packages
sudo dnf install zsh fortune-mod figlet git htop neofetch aria2 curl ncdu \
    python3-pip python3-venv bat p7zip-full ripgrep schedtool ccache

# Install Ookla Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
sudo dnf install speedtest

# Install bottom
sudo dnf copr enable atim/bottom -y
sudo dnf install bottom

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo dnf copr enable jerrycasiano/FontManager -y
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/vscode
sudo dnf update --refresh
sudo dnf install microsoft-edge-dev code-insiders font-manager
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
