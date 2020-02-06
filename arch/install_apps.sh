sudo pacman -Sy firefox vlc telegram-desktop steam

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd

yay -Sy visual-studio-code-insiders thermald cpupower cpupower-gui