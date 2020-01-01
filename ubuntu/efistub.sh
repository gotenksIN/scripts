sudo touch /etc/kernel/postinst.d/zz-update-efistub
sudo echo '#!/bin/sh' >> /etc/kernel/postinst.d/zz-update-efistub
sudo echo 'cp /boot/vmlinuz /boot/initrd.img /boot/efi/EFI/ubuntu/' >> /etc/kernel/postinst.d/zz-update-efistub
sudo chmod +x /etc/kernel/postinst.d/zz-update-efistub
sudo /etc/kernel/postinst.d/zz-update-efistub
sudo apt autoremove --purge -y grub-common grub-pc
sudo apt install -y efibootmgr

#
#Make a efistub entry using the following command
#
#sudo efibootmgr --create --disk $DISK --part $NUM --loader $LOADER --label "$LABEL" --unicode 'root=UUID=$UUID rw initrd=$INIT' --verbose
#