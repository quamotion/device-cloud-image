#!/bin/bash

# Clean up apt cache
apt-get autoremove
apt-get clean
aptitude clean

# Clean up temporary files, history,...
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* ~/.bash_history
rm -rf /root/.local/

# Ansible files
rm -rf /root/.ansible*

# Reset mache ID & friends
[ -e /var/lib/dbus/machine-id ] && rm /var/lib/dbus/machine-id
[ -e /sbin/initctl ] && rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
