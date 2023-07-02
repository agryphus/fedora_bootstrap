# Painstakingly implementing XDG file structure.
# Some programs do not like to play ball with this system.

username=$(whoami)

export HOME="/home/$username"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
mkdir -p "$XDG_CONFIG_HOME/npm"
touch $NPM_CONFIG_USERCONFIG
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
mkdir -p "$XDG_CONFIG_HOME/readline"
touch $INPUTRC
export GIT_CONFIG="$XDG_CONFIG_HOME/git/config"
mkdir -p "$XDG_CONFIG_HOME/git"
touch $GIT_CONFIG
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
mkdir -p $CARGO_HOME
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
mkdir -p $RUSTUP_HOME
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
mkdir -p $GNUPGHOME
export NPM_CONFIG_PREFIX="$XDG_CACHE_HOME/npm"
mkdir -p $NPM_CONFIG_PREFIX
export VIMINFO="$XDG_STATE_HOME/vim/viminfo"
mkdir -p $XDG_STATE_HOME/vim
touch $VIMINFO
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"

