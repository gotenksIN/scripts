sudo touch /etc/kernel/postinst.d/zz-update-efistub
echo '#!/bin/sh' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
echo 'cp /boot/vmlinuz /boot/initrd.img /boot/efi/EFI/ubuntu/' | sudo tee -a /etc/kernel/postinst.d/zz-update-efistub
sudo chmod +x /etc/kernel/postinst.d/zz-update-efistub
sudo /etc/kernel/postinst.d/zz-update-efistub
sudo apt autoremove --purge -y grub-common grub-pc
sudo apt install -y efibootmgr

#
#Make a efistub entry using the following command
#
sudo efibootmgr --create --disk "$DISK" --part "$NUM" --loader "$LOADER" --label "$LABEL" --unicode "root=UUID=$UUID rw initrd=$INIT" --verbose
#
