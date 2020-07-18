#!/bin/bash

sudo rm -rf /var/cache/snapd/

sudo apt autoremove --purge snapd gnome-software-plugin-snap apparmor ^avahi rsyslog apport ^vim mobile-broadband-provider-info popularity-contest bolt \
hexchat thunderbird transmission libreoffice gnome-orca gnote graphviz imagemagick celluloid rhythmbox redshift fonts-arundina \
gnome-2048 gnome-calculator gnome-calendar gnome-chess gnome-mahjongg gnome-software-plugin-snap gnome-sudoku gnome-system-monitor gnome-disk-utility \
gnome-online-accounts gnome-session-common language-selector-common language-selector-gnome language-pack-de-base language-pack-es-base \
hunspell-de-at-frami hunspell-de-ch-frami hunspell-de-de-frami hunspell-en-au hunspell-en-ca hunspell-en-za hunspell-es hunspell-fr \
hunspell-fr-classical hunspell-it hunspell-pt-br hunspell-pt-pt hunspell-ru language-pack-fr-base language-pack-gnome-en-base language-pack-pt-base language-pack-ru-base \
fonts-beng fonts-deva fonts-gujr fonts-indic fonts-knda fonts-mlym fonts-orya fonts-smc fonts-taml fonts-telu fonts-tibetan-machine fonts-thai-tlwg \
fonts-kacst fonts-kacst-one fonts-khmeros-core fonts-lao fonts-lklug-sinhala fonts-sil-abyssinica fonts-sil-padauk fonts-arphic-ukai fonts-arphic-uming \

rm -rf ~/snap

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
