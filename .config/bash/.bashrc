# .bashrc
# shellcheck shell=bash
[ -z "${BASH_VERSION:-}" ] && return
[[ $- != *i* ]] && return
unset MAILCHECK
shopt -s autocd checkwinsize histappend

if [[ "${HOSTNAME:-}" == 'toolbox' ]] || [[ "${HOSTNAME:-}" == 'distrobox' ]]; then
    return
fi

    . /home/vlk/bin/vlkenv

if [[ $- == *i* ]] && \
        [ -z "${NO_BLE:-}" ] && \
        ( [[ "$TERM" == *'xterm'* ]] || [[ "$TERM" == *'256'* ]] ); then
    __bleargs="--noattach --rcfile ${BDOTDIR}/blerc"
    if [ -f '/usr/share/blesh/ble.sh' ]; then
        . '/usr/share/blesh/ble.sh' $__bleargs
    elif [ -f "${XDG_DATA_HOME:=$HOME/.local/share}/gitmgmt/ble.sh/out/ble.sh" ]; then
        . "${XDG_DATA_HOME}/gitmgmt/ble.sh/out/ble.sh" $__bleargs
    fi
    unset __bleargs
fi

. /home/vlk/bin/vlkrc

HISTFILE="$XDG_STATE_HOME/bash_history"
export HISTCONTROL=erasedups:ignoreboth

export CURRENT_SHELL='bash'

export PS1='\[\e[0;31m\][\[\e[0;2;32m\]\s\[\e[0;2;31m\]] \[\e[0;95m\]$? \[\e[0;1;3;4;96m\]\w\[\e[0;1;92m\] \$ \[\e[0m\]'
# stolen from TehBoss#4823 on discord, suck it nerd lmaooo
[[ "$ICON_TYPE" != 'fallback' ]] && PROMPT_COMMAND=__prompt_command
__prompt_command() {
    local exit="$?"
    # Add user
    PS1="\[\e[97m\]\[\e[48;5;25m\] \u\[\e[38;5;25m\]"
    # Add dir code
    PS1+="\[\e[48;5;238m\]\[\e[97m\] \w\[\e[0m\]\[\e[38;5;238m\]"

    if ((exit != 0)); then
        PS1+="\[\e[48;5;124m\]\[\e[97m\] ${exit}\[\e[0m\]\[\e[38;5;124m\]"
    else
        PS1+=''
    fi
    PS1+="\[\e[0m\] "
}

printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | lolcat

[ -z "${BLE_VERSION:-}" ] && : || ble-attach
