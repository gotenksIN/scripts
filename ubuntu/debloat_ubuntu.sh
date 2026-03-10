#!/usr/bin/env bash

sudo snap remove firefox

sudo apt autoremove --purge snapd gnome-software-plugin-snap apparmor rsyslog apport ^vim mobile-broadband-provider-info ^cloud \
hexchat thunderbird transmission ^libreoffice gnote graphviz ^imagemagick celluloid rhythmbox redshift ^cups ^printer-driver print-manager \
gnome-2048 gnome-calculator gnome-calendar gnome-chess gnome-mahjongg gnome-software-plugin-snap gnome-sudoku bolt ^libreoffice \
language-pack-de-base language-pack-es-base popularity-contest language-pack-ru-base gnome-disk-utility gnome-font-viewer ^gnome-games \
hunspell-de-at-frami hunspell-de-ch-frami hunspell-de-de-frami hunspell-en-au hunspell-en-ca hunspell-en-za hunspell-es hunspell-fr \
hunspell-fr-classical hunspell-it hunspell-pt-br hunspell-pt-pt hunspell-ru language-pack-fr-base language-pack-pt-base unattended-upgrades \
plasma-discover kate elisa haruna info kinfocenter kcalc kcharselect kdeconnect partitionmanager kmahjongg kmines krdc plasma-systemmonitor \
kpat ksudoku ksystemlog neochat okular skanlite skanpage usb-creator-kde memtest86+

sudo rm -rf /var/cache/snapd/ ~/snap

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
