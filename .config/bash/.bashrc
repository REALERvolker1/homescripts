# .bashrc
# shellcheck shell=bash

{ [ -n "${BASH_VERSION:-}" ] && [[ $- == *i* ]]; } || return 69

shopt -s autocd cdspell cmdhist checkwinsize histappend
bind "set completion-ignore-case on"

for i in \
    '/etc/bashrc' '/etc/bash.bashrc' \
    "$HOME/bin/vlkenv" \
    '/usr/share/blesh/ble.sh' "$XDG_DATA_HOME/gitmgmt/ble.sh/out/ble.sh" \
    "$HOME/bin/vlkpromptrc" \
    "$HOME/bin/vlkrc"; do
    [[ "$i" == *'ble.sh' ]] && ba='--noattach' || ba=''
    [ -f "$i" ] && . "$i" "$ba"
done
unset i ba

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
