#!/usr/bin/env bash

#Install drivers
sudo apt update && sudo apt install nvidia-driver
sudo apt install bumblebee-nvidia primus

#No screen tearing when using Intel card
sudo cat >> /usr/share/X11/xorg.conf.d/20-intel.conf << EOL
Section "Device"
	Identifier "Intel Graphics"
	Driver "intel"
	Option "TearFree" "true"
EndSection
EOL

#Next nvidia configuration file
sudo cat >> /etc/bumblebee/xorg.conf.nvidia << EOL
Section "Screen"
	Identifier "Default Screen"
	Device "DiscreteNvidia"
EndSection
EOL

#Installing OpenCL driver to make your hashcat and any other GUI programs work
sudo apt install -y ocl-icd-libopencl1 nvidia-cuda-toolkit

echo "Do you want to reboot now [Y/n] ?"
read inputs
if [$inputs == "Y" || $inputs == "y"]; then
	reboot
fi
