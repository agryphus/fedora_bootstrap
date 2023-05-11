#!/usr/bin/bash
# Fedora uses bash out of the box
# Simple script to setup my Fedora environment the way I like it.
# Version: 36 (Container Image)

# Download passwd first.
echo "Installing passwd... Might take a second to update dnf."
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
dnf install -y passwd

# Create new user
echo -n "Username: "
read username 
echo "Hello, $username"
useradd $username 
usermod -aG wheel $username # Grant sudo
passwd $username

# Treat user's home as new home for rest of script
export HOME=/home/$username

# Git account info
echo -n "Git username: "
read git_username
echo -n "Git email: "
read git_email
set_git=true
if [ "$git_username" = "" ] || [ "$git_email" = "" ]; then
    set_git=false
fi

# Copy over git private key
echo -n "Git id_rsa location (skip if you don't have one): "
read -e id_rsa
id_rsa="${id_rsa/#\~/$HOME}"
use_ssh=false
if [ -f "$id_rsa" ]; then
    use_ssh=true
    cd ~
    test -d ./.ssh || mkdir .ssh
    cd ./.ssh
    cp $id_rsa ./id_rsa
    chown $username:$username ./id_rsa
    chmod 600 ./id_rsa
fi

# Packages
dnf install -y clang
dnf install -y dash
dnf install -y dos2unix
dnf install -y git
dnf install -y ncurses
dnf install -y neovim python3-neovim
dnf install -y npm
dnf install -y ripgrep
dnf install -y systemd
dnf install -y unzip
dnf install -y util-linux-user
dnf install -y zsh

# Rust
curl --proto '=https' --tlsv1.2 -sSf http://sh.rustup.rs | sh -s -- -y

# Configure git
if $set_git; then
    git config --global user.name $git_username
    git config --global user.email $git_email
fi

# Change shells
chsh -s /usr/bin/zsh $username # ZSH as interactive shell
ln -sf /bin/dash /bin/sh       # Dash as /bin/sh

# Get nvim config
cd ~
test -d ./.config || mkdir .config
cd .config
git clone https://github.com/agryphus/nvim.git
if $use_ssh; then
    git remote set-url origin git@github.com:agryphus/nvim.git
fi

# Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 	~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Copy over dotfiles
cd ~/.config
git clone https://github.com/agryphus/dotfiles.git
if $use_ssh; then
    git remote set-url origin git@github.com:agryphus/dotfiles.git
fi

# Setup zsh
echo "ZDOTDIR=~/.config/dotfiles" >> /etc/zshenv
cd ~/.config 
mkdir zsh && cd zsh 
mkdir plugins && cd plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# Editing WSL configuration
touch /etc/wsl.conf
echo "[interop]
appendWindowsPath=false

[boot]
systemd=true
" >> /etc/wsl.conf

# Finish up
cd ~
chown -R $username:$username ~
echo "Finished setup. Some changes will require restarting WSL."
su $username

