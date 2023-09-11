# .bashrc
# shellcheck shell=bash
[ -z "${BASH_VERSION:-}" ] && return
[[ $- != *i* ]] && return
unset MAILCHECK
shopt -s autocd checkwinsize histappend

for i in \
    '/etc/bashrc' \
    '/etc/bash.bashrc' \
    "$HOME/bin/vlkenv" \
    '/usr/share/blesh/ble.sh' \
    "$XDG_DATA_HOME/gitmgmt/ble.sh/out/ble.sh" \
    "$HOME/bin/vlkpromptrc" \
    "$HOME/bin/vlkrc"; do
    [ -f "$i" ] || continue
    if [[ "$i" == *'ble.sh' ]]; then
        . "$i" --noattach
    else
        . "$i"
    fi
done
unset i

__cd_ls() {
    builtin cd "$@"
    declare -i retval="$?"
    ((retval != 0)) && return "$retval"
    declare -i fcount="$($(which --skip-alias ls) -A1 | wc -l)"
    if ((fcount < 30)); then
        if command -v lsd &>/dev/null; then
            lsd
        else
            ls
        fi
    else
        local bash_sucks_ass="${LS_COLORS:-01;34}"
        bash_sucks_ass="${bash_sucks_ass##*:di=}"
        echo -e "\e[${bash_sucks_ass%%:*}m${fcount}\e[0m items in this folder"
    fi
}
alias cd=__cd_ls

HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL=erasedups:ignoreboth

if command -v figlet &>/dev/null; then
    printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | (command -v lolcat &>/dev/null && lolcat || tee)
fi
[ -n "${CONTAINER_ID}" ] && export PATH="$HOME/bin:$PATH"
if [[ ${BLE_VERSION-} ]]; then
    ble-attach
fi
