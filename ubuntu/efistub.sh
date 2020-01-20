#
#Add kernel and initramfs to your boot partition
#
sudo touch /etc/kernel/postinst.d/zz-update-efistub
echo '#!/bin/sh' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
echo 'cp /boot/vmlinuz /boot/initrd.img /boot/efi/EFI/ubuntu/' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
sudo chmod +x /etc/kernel/postinst.d/zz-update-efistub
sudo /etc/kernel/postinst.d/zz-update-efistub
#
#Remove grub and all it's dependencies
#
sudo apt autoremove --purge -y grub-common grub-pc
sudo apt install -y efibootmgr
