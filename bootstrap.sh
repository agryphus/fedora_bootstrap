#!/usr/bin/sh

# Create new user
echo -n "Username: "
read username 
echo "Hello, $username"
useradd $username 
usermod -aG wheel $username # Grant sudo

# Create password
dnf install -y passwd
passwd $username

# Treat user's home as new home for rest of script
export HOME=/home/$username

# Packages
dnf install -y zsh
dnf install -y ncurses
dnf install -y ripgrep
dnf install -y neovim python3-neovim
dnf install -y npm
dnf install -y clang
dnf install -y unzip
dnf install -y git

# Get nvim config
cd ~
test -d ./.config || mkdir .config
cd .config
git clone https://github.com/agryphus/nvim.git

# Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 	~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Setup zsh
# ~copy .zshrc lol~
cd ~/.config 
mkdir zsh && cd zsh 
mkdir plugins && cd plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# Finish up
chown -R $username:$username ~
cd ~
exec zsh

