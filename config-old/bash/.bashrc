# .bashrc
# shellcheck shell=bash disable=1090,1091

[[ -n $BASH_VERSION && -z $BASHRC_LOADED && $- == *i* && ${BASH_VERSINFO[0]} -gt 4 ]] || {
    return
    exit
}
# NO_BLE=true

echo "I use zsh as my login shell now"
return

# shell options
set +xeuo pipefail
shopt -s autocd cdspell cdable_vars cmdhist checkwinsize histappend globstar
bind "set completion-ignore-case on"
HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL='erasedups:ignoreboth'

rsrc() {
    [[ -r ${1-} ]] && . "$@"
}

for i in \
    /etc/{bashrc,bash.bashrc} \
    ~/bin/vlk{env,rc}; do
    rsrc "$i"
done

# some aliases
cd() {
    builtin cd "$@" || return
    local -i fcount
    fcount="$(builtin printf '%s\n' {.,}* | command grep -cEv '^(\.|)\*$')"
    if ((fcount < 30)); then
        ls
    else
        builtin echo -e "\e[0;1;94m${fcount}\e[0m items in this folder"
    fi
}

for i in ..{,.,..}; do
    alias ".${i}=cd ${i//./../}"
done

unset i

# source bash completion if I haven't already
if [[ -z ${BASH_COMPLETION_VERSINFO-} ]]; then
    rsrc "${BDOTDIR:=$HOME}/bash_completion"
    rsrc /usr/share/bash-completion/bash_completion
fi

# bash plugins
export BPLUGIN_DIR="$XDG_DATA_HOME/bash-plugins"
if [[ ! -f "$BPLUGIN_DIR/blesh/out/ble.sh" ]] && command -v git mkdir make &>/dev/null; then
    echo -e "\e[1mCloning ble.sh\e[0m"
    __ble_cwd="$PWD"
    mkdir -p "$BPLUGIN_DIR/blesh" || return
    git clone 'https://github.com/akinomyoga/ble.sh.git' "$BPLUGIN_DIR/blesh"
    builtin cd "$BPLUGIN_DIR/blesh" || return
    make
    builtin cd "$__ble_cwd" || return
    unset __ble_cwd
fi
unset PROMPT_COMMAND
[[ ${TERM:-linux} != linux && -z ${NO_BLE-} ]] && rsrc "$BPLUGIN_DIR/blesh/out/ble.sh" --noattach
# if [[ $TERM != linux ]] && command -v atuin &>/dev/null; then
# [[ ! -f "$BDOTDIR/atuin-init.bash" ]] && atuin init bash >"$BDOTDIR/atuin-init.bash"
# . "$BDOTDIR/atuin-init.bash"
# fi

PS1="\[\e[0m\]\n\$(r=\"\$?\";((r>0))&&echo \"\[\e[1;91m\]\$r\[\e[0m\] \")\[\e[1m\][\[\e[0;92m\]\u\[\e[0m\]$([[ "${HOSTNAME:=$(cat /etc/hostname)}" != "${CURRENT_HOSTNAME:-ud}" ]] && echo '@\[\e[94m\]\H\[\e[0m\]')\[\e[1m\]]\[\e[0m\]\[\e[${DIRECTORY_COLOR:=1;34}m\] \w \[\e[0m\]$ "

printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | lolcat

BASHRC_LOADED=true
if [[ ${BLE_VERSION-} ]]; then
    ble-attach
else
    :
fi
