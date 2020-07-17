#!/bin/bash

sudo rm -rf /var/cache/snapd/

sudo apt autoremove --purge snapd gnome-software-plugin-snap apparmor ^avahi rsyslog apport ^vim mobile-broadband-provider-info popularity-contest \
fonts-beng fonts-deva fonts-gujr fonts-indic fonts-knda fonts-mlym fonts-orya fonts-smc fonts-taml fonts-telu fonts-tibetan-machine fonts-thai-tlwg

rm -rf ~/snap

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
