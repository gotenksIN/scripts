#Remove grub and all it's dependencies

sudo apt autoremove --purge -y grub-common grub-pc
sudo apt install -y efibootmgr