#!/bin/bash

#blacklist the Nouveau driver
sudo cat >> /etc/modprobe.d/blacklist-nouveau.conf <<EOL
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off 
alias lbm-nouveau off
EOL

echo -n "Do you want to reboot now [y/n]: "
read -r -n1 input
if [[ "$input" =~ ^[Yy]$ ]]; then
        reboot
fi
