#Install all packages required for cinnamon to work nicely
sudo pacman -Sy cinnamon gnome-terminal gnome-screenshot lightdm eog nemo-fileroller rhythmbox gedit evince
localectl set-locale LANG=en_US.UTF-8

#Install packages related to bluetooth as needed
echo "Do you have any bluetooth adaptors installed? (Y/n)"
read input
if [[ $input == "Y" || $input == "y" ]]; then
sudo pacman -Sy blueberry
sudo systemctl enable bluetooth.service
fi

#Enable some services for convenience
sudo systemctl enable NetworkManager.service
sudo systemctl disable NetworkManager-wait-online.service

#Setup lightdm along with slick-greeter plus necessary configs
git clone https://aur.archlinux.org/lightdm-slick-greeter
cd lightdm-slick-greeter
makepkg -si
cd
sudo su
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
exit
