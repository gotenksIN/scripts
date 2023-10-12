#!/usr/bin/env bash

sudo snap remove firefox

sudo apt autoremove --purge snapd gnome-software-plugin-snap apparmor rsyslog apport ^vim mobile-broadband-provider-info ^cloud \
hexchat thunderbird transmission ^libreoffice gnome-orca gnote graphviz ^imagemagick celluloid rhythmbox redshift fonts-arundina \
gnome-2048 gnome-calculator gnome-calendar gnome-chess gnome-mahjongg gnome-software-plugin-snap gnome-sudoku bolt ^libreoffice \
language-pack-de-base language-pack-es-base popularity-contest language-pack-ru-base gnome-disk-utility gnome-font-viewer ^gnome-games \
hunspell-de-at-frami hunspell-de-ch-frami hunspell-de-de-frami hunspell-en-au hunspell-en-ca hunspell-en-za hunspell-es hunspell-fr \
hunspell-fr-classical hunspell-it hunspell-pt-br hunspell-pt-pt hunspell-ru language-pack-fr-base language-pack-pt-base unattended-upgrades \
fonts-beng fonts-deva fonts-gujr fonts-indic fonts-knda fonts-mlym fonts-orya fonts-smc fonts-taml fonts-telu fonts-tibetan-machine fonts-thai-tlwg \
fonts-kacst fonts-kacst-one fonts-khmeros-core fonts-lao fonts-lklug-sinhala fonts-sil-abyssinica fonts-sil-padauk fonts-arphic-ukai fonts-arphic-uming

sudo rm -rf /var/cache/snapd/ ~/snap

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
