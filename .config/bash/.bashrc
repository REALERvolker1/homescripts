# .bashrc
# shellcheck shell=bash disable=1090,1091

[[ -n $BASH_VERSION && -z $BASHRC_LOADED && $- == *i* && ${BASH_VERSINFO[0]} -gt 4 ]] || {
    return
    exit
}
BASHRC_LOADED=true
# NO_BLE=true

shopt -s autocd cdspell cmdhist checkwinsize histappend
bind "set completion-ignore-case on"

for i in \
    '/etc/bashrc' '/etc/bash.bashrc' \
    ~/bin/vlkenv \
    ~/bin/vlkrc; do
    [[ -r $i ]] && . "$i"
done
unset i
# /etc/profile.d/bash_completion.sh \

cd() {
    builtin cd "$@" || return
    local -i fcount
    fcount="$(printf '%s\n' ./.* ./* | grep -cEv '\./(\.|)\*$')"
    if ((fcount < 30)); then
        "$LS_COMMAND"
    else
        echo -e "\e[0;${DIRECTORY_COLOR:=1;34}m${fcount}\e[0m items in this folder"
    fi
}

if [[ -z ${BASH_COMPLETION_VERSINFO:-} ]]; then
    [[ -r ${BDOTDIR:-$HOME}/bash_completion ]] && . "${BDOTDIR:-$HOME}/bash_completion"
    shopt -q progcomp && [[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
fi

export BPLUGIN_DIR="$XDG_DATA_HOME/bash-plugins"
if [[ ! -f "$BPLUGIN_DIR/blesh/out/ble.sh" ]] && command -v git &>/dev/null; then
    echo -e "\e[1mCloning ble.sh\e[0m"
    __ble_cwd="$PWD"
    mkdir -p "$BPLUGIN_DIR/blesh" || return
    git clone 'https://github.com/akinomyoga/ble.sh.git' "$BPLUGIN_DIR/blesh"
    builtin cd "$BPLUGIN_DIR/blesh" || return
    make
    builtin cd "$__ble_cwd" || return
    unset __ble_cwd
fi
# --rcfile
[[ $TERM != linux && -z $NO_BLE && -f "$BPLUGIN_DIR/blesh/out/ble.sh" ]] && . "$BPLUGIN_DIR/blesh/out/ble.sh" --noattach
if [[ $TERM != linux ]] && command -v atuin &>/dev/null; then
    [[ ! -f "$BDOTDIR/atuin-init.bash" ]] && atuin init bash >"$BDOTDIR/atuin-init.bash"
    . "$BDOTDIR/atuin-init.bash"
fi

unset PROMPT_COMMAND
PS1="\[\e[0m\]\n\$(r=\"\$?\";((r>0))&&echo \"\[\e[1;91m\]\$r\[\e[0m\] \")\[\e[1m\][\[\e[0;92m\]\u\[\e[0m\]$([[ "${HOSTNAME:=$(cat /etc/hostname)}" != "${CURRENT_HOSTNAME:-ud}" ]] && echo '@\[\e[94m\]\H\[\e[0m\]')\[\e[1m\]]\[\e[0m\]\[\e[${DIRECTORY_COLOR:=1;34}m\] \w \[\e[0m\]$ "

HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL='erasedups:ignoreboth'

printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | lolcat

[[ $BLE_VERSION ]] && ble-attach || :
