script_dir=$(dirname "$(readlink -f "$0")")
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    . $script_dir/common/envset.sh
else
    . $script_dir/scripts/common/envset.sh
fi

# Git account info
echo -n "Setup git config? [y/n]: "
read set_git_prompt
if [ "$set_git_prompt" = "y" ]; then
    echo -n "Git username: "
    read git_username
    echo -n "Git email: "
    read git_email
    git config --global user.name $git_username
    git config --global user.email $git_email
fi

# Copy over dotfiles
cd ~/.config
if $use_ssh; then
    git clone git@github.com:agryphus/dotfiles.git
else
    git clone https://github.com/agryphus/dotfiles.git
fi

# Setup zsh
sudo sh -c '"ZDOTDIR=~/.config/zsh/" >> /etc/zsh/zshenv'
mkdir -p ~/.config/zsh/plugins
cd ~/.config/zsh/plugins/
if $use_ssh; then
    git clone git@github.com:zsh-users/zsh-syntax-highlighting.git
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
fi
ln ~/.config/dotfiles/zshrc ~/.config/zsh/.zshrc
ln ~/.config/dotfiles/zprofile ~/.config/zsh/.zprofile

# Get nvim config
cd ~/.config
if $use_ssh; then
    git clone git@github.com:agryphus/nvim.git
else
    git clone https://github.com/agryphus/nvim.git
fi

# Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 	~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

