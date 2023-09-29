# .bashrc
# shellcheck shell=bash

if [ -z "${BASH_VERSION:-}" ] || [ -n "${BASHRC_LOADED:-}" ] || [[ $- != *i* ]]; then
    echo "doublesourced ${BASH_SOURCE:-bashrc}"
    return
    exit
fi
shopt -s autocd cdspell cmdhist checkwinsize histappend
bind "set completion-ignore-case on"

for i in \
    '/etc/bashrc' '/etc/bash.bashrc' \
    "$HOME/bin/vlkenv" \
    "$HOME/bin/vlkpromptrc" \
    "$HOME/bin/vlkrc"; do
    [ -f "$i" ] && . "$i" "$ba"
done
unset i ba

#. "$XDG_DATA_HOME/gitmgmt/ble.sh/out/ble.sh" --noattach
export BPLUGIN_DIR="$XDG_DATA_HOME/bash-plugins"
[ ! -f "$BPLUGIN_DIR/blesh/out/ble.sh" ] && command -v git &>/dev/null && {
    echo -e "\e[1mCloning ble.sh\e[0m"
    __ble_cwd="$PWD"
    mkdir -p "$BPLUGIN_DIR/blesh" || return
    git clone 'https://github.com/akinomyoga/ble.sh.git' "$BPLUGIN_DIR/blesh"
    cd "$BPLUGIN_DIR/blesh" || return
    make
    cd "$__ble_cwd"
    unset __ble_cwd
} || :
[ -f "$BPLUGIN_DIR/blesh/out/ble.sh" ] && . "$BPLUGIN_DIR/blesh/out/ble.sh" --noattach

HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL='erasedups:ignoreboth'

__cd_ls() {
    builtin cd "$@" || return
    local -i fcount="$($(which --skip-alias ls) -A1 | wc -l)"
    ((fcount < 30)) && ls || echo -e "\e[1;94m${fcount}\e[0m items in this folder"
}
alias cd=__cd_ls

printf '%s -%s' "${0##*/}" "$-" | (
    if command -v figlet &>/dev/null; then
        figlet -f smslant -w "$COLUMNS"
    else
        tee
    fi
) | (
    if command -v lolcat &>/dev/null; then
        lolcat
    else
        tee
    fi
)

[[ ${BLE_VERSION:-} ]] && ble-attach || :
BASHRC_LOADED=true
