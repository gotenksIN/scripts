#!/usr/bin/env bash

# Run the script with root, sudo somehow breaks it

read -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -e -p "Enter loader name (e.g. vmlinuz-linux): " -i "vmlinuz-linux" loader
read -e -p "Enter initrd name (e.g. initramfs-linux.img): " -i "initramfs-linux.img" initrd
read -e -p "Enter label for this entry (Label is what would show up in UEFI entries): " -i "rendumOS (efistub)" label
read -e -p "Enter any extra arguments you want to pass to kernel cmdline: " extra

read -e -p "Do you have an Intel or AMD CPU? (Y/n): " input
if [[ "$input" =~ ^[Yy]$ ]]; then
        read -e -p "Enter 1 for Intel and 2 for AMD: " cpu
        if [[ "$cpu" =~ ^[1]$ ]]; then
        pacman -Sy intel-ucode
        microcode="\intel-ucode.img"
        printf -v largs "%s " \
                "root=UUID=$(findmnt -kno UUID /) rw" \
                "rootfstype=$(findmnt -kno FSTYPE /)" \
                "initrd"=${microcode} "initrd=${initrd}" \
                quiet splash
        else
        pacman -Sy amd-ucode
        microcode="\amd-ucode.img"
        printf -v largs "%s " \
                "root=UUID=$(findmnt -kno UUID /) rw" \
                "rootfstype=$(findmnt -kno FSTYPE /)" \
                "initrd"=${microcode} "initrd=${initrd}" \
                initcall_blacklist=acpi_cpufreq_init \
                amd_pstate.shared_mem=1 \
                quiet splash
        fi
else
        printf -v largs "%s " \
                "root=UUID=$(findmnt -kno UUID /) rw" \
                "rootfstype=$(findmnt -kno FSTYPE /)" \
                "initrd=${initrd}" quiet splash
fi

efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l "${loader}" -u "${largs%* } ${extra}" --verbose
