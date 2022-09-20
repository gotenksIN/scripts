#!/usr/bin/env bash

# Install dnf5
sudo dnf copr enable rpmsoftwaremanagement/dnf5-unstable -y
sudo dnf install dnf5 -y

# Upgrade installed packages
sudo dnf5 upgrade

# Enable RPM Fusion repositories
sudo dnf5 install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf5 install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf groupupdate core

# Install frequently used packages
sudo dnf5 install zsh fortune-mod figlet git htop neofetch aria2 curl ncdu \
    python3-pip bat p7zip ripgrep schedtool ccache telegram-desktop util-linux-user

# Install Ookla Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
sudo dnf5 install speedtest

# Install bottom
sudo dnf copr enable atim/bottom -y
sudo dnf5 install bottom

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo dnf copr enable jerrycasiano/FontManager -y
sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate sound-and-video
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/vscode
sudo dnf5 upgrade
sudo dnf5 install microsoft-edge-dev code-insiders font-manager gnome-tweaks papirus-icon-theme
fi

# Setup zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
chsh -s /usr/bin/zsh
