#!/usr/bin/bash
# openSUSE uses bash out of the box
# Simple script to setup my openSUSE environment the way I like it.
# Version: Tumbleweed (rolling release)

script_dir=$(dirname "$(readlink -f "$0")")

# Editing WSL configuration
touch /etc/wsl.conf
echo "[interop]
appendWindowsPath=false

[boot]
systemd=true
" >> /etc/wsl.conf

# Packages
zypper in -y binutils clang clang-devel dash gcc gcc-c++ git neovim npm python3-neovim ripgrep system-group-wheel tmux zsh

# Crucify me for changing the sudoers file this way, their
# fault for there not being more explicit commands to do this.
sed -i '/^Defaults targetpw/s/^/# /' /etc/sudoers
sed -i '/^ALL   ALL=(ALL) ALL   #/s/^/# /' /etc/sudoers
sed -i 's/^#\s*\(%wheel\s*ALL=(ALL:ALL)\s*ALL\)/\1/' /etc/sudoers

# Create new user
echo -n "Username: "
read username
echo "Hello, $username"
useradd $username -g wheel -m
passwd $username

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

export HOME="/home/$username"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export EMACS_INIT_FILE="$XDG_CONFIG_HOME/emacs"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export GIT_CONFIG="$XDG_CONFIG_HOME/git/config"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export NPM_CONFIG_PREFIX="$XDG_CACHE_HOME/npm"
export VIMINFO="$XDG_STATE_HOME/vim/viminfo"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"

# Enable ssh using gpg
cd ~
test -d "$GNUPGHOME" || mkdir "$GNUPGHOME"
echo "enable-ssh-support" >> "$GNUPGHOME/gpg-agent.conf"

echo -n "Use ssh to download git repos? [y/n]: "
read use_ssh_prompt
use_ssh=false
if [ "$use_ssh_prompt" = "y" ]; then
    use_ssh=true

    # Adding github to known hosts manually since the prompt
    # to add it does not want to be skipped with `yes yes`
    test -d ~/.ssh || mkdir ~/.ssh
    touch ~/.ssh/known_hosts
    curl --silent https://api.github.com/meta | \
        python3 -c 'import json,sys;print(*["github.com " + x for x in json.load(sys.stdin)["ssh_keys"]], sep="\n")' \
        >> ~/.ssh/known_hosts

    # Let root see allowed hosts until session closes
    # (despite setting $HOME, ssh will still look in /root/ssh/)
    cp -r ~/.ssh/ /root/.ssh/

    # Enable gpg ssh support
    echo enable-ssh-support > "$GNUPGHOME/gpg-agent.conf"
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi
    export GPG_TTY=$(tty) # Set pinentry tty
    eval $(gpg-agent --daemon)

    # Copy over gpg keyring
    echo -n "GPG key location: "
    read -e gpg_key
    gpg_key="${gpg_key/#\~/$HOME}" # Make absolute path
    gpg --import $gpg_key

    # Get the keygrip of the gpg auth sub key
    keygrip=`gpg --list-keys --with-keygrip | \
        grep -A1 "sub" | grep "Keygrip" | \
        awk '{print $NF}'`
    echo $keygrip > "$GNUPGHOME/sshcontrol"
fi
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/*
chmod 700 $GNUPGHOME
chmod 600 $GNUPGHOME/*

# Configure git
if $set_git; then
    sudo -u $username git config --global user.name $git_username
    sudo -u $username git config --global user.email $git_email
fi

# Copy over dotfiles
cd ~/.config
if $use_ssh; then
    git clone git@github.com:agryphus/dotfiles.git
else
    git clone https://github.com/agryphus/dotfiles.git
fi

# Setup zsh
echo "ZDOTDIR=~/.config/zsh/" >> /etc/zshenv
cd ~/.config 
mkdir zsh && cd zsh 
mkdir plugins && cd plugins
if $use_ssh; then
    git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
fi
ln ~/.config/dotfiles/zshrc ~/.config/zsh/.zshrc
ln ~/.config/dotfiles/zprofile ~/.config/zsh/.zprofile

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

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Clean up the ~ a little bit
sed -i s/^norc=false/norc=true/g /etc/profile
rm ~/.bashrc
rm ~/.bash_history
rm -rf ~/bin # Don't know why suse adds this when there is ~/.local/bin
rm ~/.profile
rm ~/.emacs
rm ~/.zshenv # Rust made this one (of course)
mkdir $XDG_CONFIG_HOME/readline
mv ~/.inputrc $INPUTRC
mkdir $XDG_CONFIG_HOME/git
mv ~/.gitconfig $GIT_CONFIG

# Change default shells
chsh -s /usr/bin/zsh $username # ZSH as interactive shell
ln -sf /bin/dash /bin/sh       # Dash as /bin/sh

# Finish up
cd /home/$username
chown -R $username:wheel .
echo "Finished setup. Please log back in an your new user."
poweroff -f

