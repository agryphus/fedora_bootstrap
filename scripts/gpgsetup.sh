script_dir=$(dirname "$(readlink -f "$0")")
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    . $script_dir/common/envset.sh
else
    . $script_dir/scripts/common/envset.sh
fi

echo -n "Copy over GPG key? [y/n]: "
read copy_gpg_key
if [ "$copy_gpg_key" = "y" ]; then

    export GPG_TTY=$(tty) # Set pinentry tty
    sudo killall gpg-agent
    gpg-connect-agent updatestartuptty /bye

    echo -n "GPG key location: "
    read -e gpg_key
    gpg_key="${gpg_key/#\~/$HOME}" # Make absolute path
    gpg --import $gpg_key
    echo -n "Is this GPG key also a valid git SSH key? [y/n]: "
    read use_ssh_prompt
fi

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

    # Enable gpg ssh support
    echo enable-ssh-support > "$GNUPGHOME/gpg-agent.conf"
    unset SSH_AGENT_PID
    if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi

    # This was plaguing me for longer than it should have.
    echo 'Match host * exec "gpg-connect-agent UPDATESTARTUPTTY /bye"' > ~/.ssh/config
    sudo systemctl restart sshd

    # Get the keygrip of the gpg auth sub key
    keygrip=`gpg --list-keys --with-keygrip | \
        grep -A1 "sub" | grep "Keygrip" | \
        awk '{print $NF}'`
    echo $keygrip > "$GNUPGHOME/sshcontrol"
fi

chmod 700 ~/.ssh/
chmod 600 ~/.ssh/*
find $GNUPGHOME -type d -exec chmod 700 {} \;
find $GNUPGHOME -type f -exec chmod 600 {} \;
# Here is your friendly reminder to never set a subdirectory as 600.  I had blindly
# done chmod 600 $GNUPGHOME/* before which would then make my private keys disappear,
# since they are kept in a subdirectory which, when 600'd, were inaccessible. (whoopsies)

