#!/bin/bash
echo "Change the drive encryption password (the old one is \"password\")"
cryptsetup luksChangeKey /dev/sda2
echo -n "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo -n "Primary username: "
read username
echo "Hello, $username"
useradd -G wheel -m $username
passwd $username
passwd -dl root # Remove root password

echo "Initial setup complete.  Please log out and log back in as the new user."

