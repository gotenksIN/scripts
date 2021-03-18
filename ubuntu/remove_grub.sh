#!/usr/bin/env bash

#Remove grub and all it's dependencies
sudo apt autoremove --purge -y --allow-remove-essential grub-common grub-pc
