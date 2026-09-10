#!/usr/bin/env bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"

# Re-run with bash as root when invoked from a user shell.
if (( EUID != 0 )); then
        exec sudo --preserve-env=TERM bash "$0" "$@"
fi

read -r -e -p "Enter your boot disk device (e.g. /dev/sda): " -i "/dev/sda" disk
read -r -e -p "Enter partition number for your boot partition (e.g. if your /boot is in /dev/sda1, enter 1): " -i "1" part
read -r -e -p "Enter loader name (e.g. vmlinuz-linux): " -i "vmlinuz-linux" loader
read -r -e -p "Enter initrd name (e.g. initramfs-linux.img): " -i "initramfs-linux.img" initrd
read -r -e -p "Enter label for this entry (Label is what would show up in UEFI entries): " -i "rendumOS (efistub)" label
read -r -e -p "Enter any extra arguments you want to pass to kernel cmdline: " extra

root_uuid=$(findmnt -kno UUID /)
root_fstype=$(findmnt -kno FSTYPE /)
swap_uuid=$(awk '$3 == "swap" && $1 !~ /^#/ { print $1; exit }' /etc/fstab)
initrd_args=("initrd=${initrd}")
kernel_args=("root=UUID=${root_uuid} rw" "rootfstype=${root_fstype}" "resume=${swap_uuid}")

read -r -e -p "Do you have an Intel or AMD CPU? (Y/n): " input
if [[ "$input" =~ ^[Yy]$ ]]; then
        read -r -e -p "Enter 1 for Intel and 2 for AMD: " cpu
        if [[ "$cpu" =~ ^[1]$ ]]; then
                pacman -Syu --needed intel-ucode
                microcode="\\intel-ucode.img"
        else
                pacman -Syu --needed amd-ucode
                microcode="\\amd-ucode.img"
        fi
        initrd_args=("initrd=${microcode}" "${initrd_args[@]}")
fi

printf -v largs "%s " \
        "${kernel_args[@]}" \
        "${initrd_args[@]}" \
        quiet

efibootmgr -c -d "${disk}" -p "${part}" -L "${label}" -l "${loader}" -u "${largs%* } ${extra}" --verbose
