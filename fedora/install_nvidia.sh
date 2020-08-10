#!/usr/bin/env bash

sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo dnf update -y

echo "Do you have Intel integrated GPU and discrete NVIDIA GPU? (Y/n)"
read inputs
if [[ $inputs == "Y" || $inputs == "y" ]]; then
sudo -s
dnf update
cat > /etc/modprobe.d/nvidia.conf <<EOF
options nvidia NVreg_DynamicPowerManagement=0x02
EOF
fi