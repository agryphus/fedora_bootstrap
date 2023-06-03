#!/usr/bin/bash
# Fedora uses bash out of the box
# Simple script to setup my Fedora environment the way I like it.
# Version: 36 (Container Image)

# Make dnf faster
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf

# Editing WSL configuration
touch /etc/wsl.conf
echo "[interop]
appendWindowsPath=false

[boot]
systemd=true
" >> /etc/wsl.conf

# Packages
dnf install -y clang dash dos2unix git hostname ncurses neovim python3-neovim npm openssh-server passwd ripgrep systemd unzip util-linux-user zsh

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Create new user
echo -n "Username: "
read username
echo "Hello, $username"
useradd $username -g wheel
passwd $username

# Treat user's home as new home for rest of script
export HOME=/home/$username

# Git account info
echo -n "Setup git account? [y/n]: "
read set_git_prompt
set_git=false
if [ "$set_git_prompt" = "y" ]; then
    set_git=true
    echo -n "Git username: "
    read git_username
    echo -n "Git email: "
    read git_email
fi

# Copy over rsa private key
echo -n "Copy over rsa key? [y/n]: "
read copy_rsa_prompt
if [ "$copy_rsa_prompt" = "y" ]; then
    echo -n "id_rsa location: "
    read -e id_rsa
    id_rsa="${id_rsa/#\~/$HOME}"
    if [ -f "$id_rsa" ]; then
        cd ~
        test -d ./.ssh || mkdir .ssh
        cd ./.ssh
        cp $id_rsa ./id_rsa
        chown $username:wheel ./id_rsa
        chmod 600 ./id_rsa
    fi
fi

echo -n "Use ssh to download git repos? [y/n]: "
read use_ssh_prompt
use_ssh=false
if [ "$use_ssh_prompt" = "y" ]; then
    use_ssh=true

    # Adding github to known hosts manually since the prompt
    # to add it does not want to be skipped with `yes yes`
    touch ~/.ssh/known_hosts
    curl --silent https://api.github.com/meta | \
        python3 -c 'import json,sys;print(*["github.com " + x for x in json.load(sys.stdin)["ssh_keys"]], sep="\n")' \
        >> ~/.ssh/known_hosts

    # Add rsa key to this session
    cp -r ~/.ssh/ /root/.ssh/
    eval `ssh-agent`
    ssh-add ~/.ssh/id_rsa
fi

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
if $use_ssh; then
    git clone git@github.com:agryphus/nvim.git
else
    git clone https://github.com/agryphus/nvim.git
fi

# Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 	~/.local/share/nvim/site/pack/packer/start/packer.nvim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Copy over dotfiles
cd ~/.config
if $use_ssh; then
    git clone git@github.com:agryphus/dotfiles.git
else
    git clone https://github.com/agryphus/dotfiles.git
fi

# Setup zsh
echo "ZDOTDIR=~/.config/dotfiles" >> /etc/zshenv
cd ~/.config 
mkdir zsh && cd zsh 
mkdir plugins && cd plugins
if $use_ssh; then
    git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
fi

# Finish up
cd ~
rm -r /root/.ssh/
chown -R $username:wheel ~
echo "Finished setup. Some changes will require restarting WSL."
su $username

