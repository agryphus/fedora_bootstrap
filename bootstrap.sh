#!/usr/bin/bash
# Fedora uses bash out of the box
# Simply script to setup my Fedora environment the way I like it.
# Version: 36 (Container Image)

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

# Copy over my git private key
echo -n "Git id_rsa location (skip if you aren't me): "
read -e id_rsa
id_rsa="${id_rsa/#\~/$HOME}"
is_me=false
if [ -f "$id_rsa" ]; then
    is_me=true
    cd ~
    test -d ./.ssh || mkdir .ssh
    cd ./.ssh
    cp $id_rsa ./id_rsa
    chown $username:$username ./id_rsa
    chmod 600 ./id_rsa
else
    is_me=false
fi

# Packages
dnf install -y util-linux-user
dnf install -y dash
dnf install -y zsh
dnf install -y ncurses
dnf install -y ripgrep
dnf install -y neovim python3-neovim
dnf install -y npm
dnf install -y clang
dnf install -y unzip
dnf install -y git

# Change shells
chsh -s /usr/bin/zsh     # ZSH as interactive shell
ln -sf /bin/dash /bin/sh # Dash as /bin/sh

# Get nvim config
cd ~
test -d ./.config || mkdir .config
cd .config
if $is_me; then
    git clone git@github.com:agryphus/nvim.git
    git config --local user.email agryphus@gmail.com
    git config --local user.name agryphus
else
    git clone https://github.com/agryphus/nvim.git
fi

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

