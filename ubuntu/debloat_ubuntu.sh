sudo rm -rf /var/cache/snapd/
sudo apt autoremove --purge snapd gnome-software-plugin-snap apparmor avahi-daemon rsyslog apport
rm -fr ~/snap
sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
