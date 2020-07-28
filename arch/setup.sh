sudo pacman -Sy ffmpeg vlc steam fortune-mod figlet zsh htop git cmatrix ncdu

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd

yay -Sy visual-studio-code-insiders google-chrome kotatogram-desktop-bin