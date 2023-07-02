#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")

# This line is a little spooky since if the script is cut off during execution,
# this sudo config will persist where the user does not need to type a password
# to run sudo commands.
sudo sed -i 's/^# \(%wheel ALL=(ALL:ALL) NOPASSWD: ALL\)/\1/' /etc/sudoers

# Download necessary packages
. $script_dir/scripts/pacman.sh

# Import gpg key and launch gpg-agent for ssh-ing
. $script_dir/scripts/gpgsetup.sh

# Start cloning app the repos I need
. $script_dir/scripts/gitclone.sh

# Change default shells
sudo chsh -s /usr/bin/zsh $username # ZSH as interactive shell
sudo ln -sf /bin/dash /bin/sh       # Dash as /bin/sh

sudo sed -i s/^norc=false/norc=true/g /etc/profile

sudo sed -i 's/^\(%wheel ALL=(ALL:ALL) NOPASSWD: ALL\)/# \1/' /etc/sudoers

# Clean up the ~ a little
rm ~/.bash_profile
rm ~/.bash_history
rm ~/.bash_logout
rm ~/.bashrc
rm ~/.viminfo

echo "Setup complete."
exec zsh
