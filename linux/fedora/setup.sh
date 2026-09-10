#!/usr/bin/env bash

sudo tee -a /etc/dnf/dnf.conf > /dev/null <<EOF
fastestmirror=True
max_parallel_downloads=10
EOF

# Upgrade installed packages
sudo dnf upgrade --refresh

# Enable RPM Fusion repositories
sudo dnf install \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Install frequently used packages
sudo dnf install zsh fortune-mod figlet git htop fastfetch aria2 curl ncdu \
    bat 7zip ripgrep schedtool ccache keychain screen wget hostname gawk

# Install Ookla Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo env os=fedora dist=41 bash
sudo sed -i 's|/etc/pki/tls/certs/ca-bundle.crt|/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem|g' /etc/yum.repos.d/ookla_speedtest-cli.repo
sudo dnf install speedtest

# Install bottom
sudo dnf install https://github.com/ClementTsang/bottom/releases/download/0.14.3/bottom-0.14.3-1.x86_64.rpm

# Guard gui dependent applications behind this
read -e -p "Do you intend on using GUI? [y/n]: " input
if [[ "$input" =~ ^[Yy]$ ]]; then
sudo dnf group upgrade multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf group upgrade sound-and-video
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
rpm -q mesa-va-drivers >/dev/null 2>&1 && sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld --allowerasing
rpm -q mesa-vdpau-drivers >/dev/null 2>&1 && sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld --allowerasing
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf config-manager addrepo --overwrite --save-filename=microsoft-edge.repo --from-repofile=https://packages.microsoft.com/yumrepos/edge/config.repo
sudo dnf config-manager addrepo --overwrite --save-filename=vscode.repo --from-repofile=https://packages.microsoft.com/yumrepos/vscode/config.repo
sudo dnf makecache --refresh
sudo dnf copr enable zeno/scrcpy
sudo dnf install microsoft-edge-stable code discord \
    flatpak scrcpy telegram-desktop vlc vlc-plugins-extra vlc-plugins-freeworld gstreamer1-plugin-openh264 \
    gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly mozilla-openh264
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Setup zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k
sudo usermod --shell /usr/bin/zsh "$USER"
