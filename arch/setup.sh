sudo pacman -Sy ffmpeg vlc steam fortune-mod figlet zsh htop git cmatrix ncdu nano

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd

yay -Sy visual-studio-code-insiders google-chrome kotatogram-desktop-bin

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USER/.oh-my-zsh/custom/themes/powerlevel10k

git config --global user.name "Omkar Chandorkar"
git config --global user.email forumomkar@gmail.com
git config --global user.signingkey 6D8DEF354ED78DE805938A9D95A33FD984777F70
git config --global gpg.program gpg
git config --global commit.gpgsign true
git config --global pull.rebase false
git config --global core.editor nano