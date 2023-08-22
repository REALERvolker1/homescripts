# .bashrc
# shellcheck shell=bash
[ -z "${BASH_VERSION:-}" ] && return
[[ $- != *i* ]] && return
unset MAILCHECK
shopt -s autocd checkwinsize histappend

# distrobox-create --name ARCH --image archlinux:latest
if [[ "${HOSTNAME:-}" == 'toolbox' ]] || [[ "${HOSTNAME:-}" == 'distrobox' ]]; then
    LIMITED_ROOT_HOST=true
    #return
fi
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

[ -f "$HOME/bin/vlkenv" ] && . "$HOME/bin/vlkenv"

if [[ "$TERM" == *'xterm'* ]] || [[ "$TERM" == *'256'* ]]; then
    if [ -z "${NO_BLE:-}" ] && [ -f "$BDOTDIR/blerc" ]; then
        __bleargs="--noattach --rcfile $BDOTDIR/blerc"
        for i in \
            '/usr/share/blesh/ble.sh' \
            "$XDG_DATA_HOME/gitmgmt/ble.sh/out/ble.sh"; do
            [ -f "$i" ] && . "$i" $__bleargs
        done
        unset i __bleargs
    fi
fi

[ -z "${LIMITED_ROOT_HOST:-}" ] && [ -f "$HOME/bin/vlkrc" ] && . "$HOME/bin/vlkrc"

HISTFILE="$XDG_STATE_HOME/bash_history"
export HISTCONTROL=erasedups:ignoreboth

# # \[escape codes\]content
# export PS1='\[\e[0;31m\][\[\e[0;2;32m\]\s\[\e[0;2;31m\]] \[\e[0;95m\]$? \[\e[0;1;3;4;96m\]\w\[\e[0;1;92m\] \$ \[\e[0m\]'
# # stolen from TehBoss#4823 on discord, suck it nerd lmaooo
# [[ "$ICON_TYPE" != 'fallback' ]] && PROMPT_COMMAND=__prompt_command
# __prompt_command() {
#     local exit="$?"
#     # Add user
#     PS1="\[\e[97m\]\[\e[48;5;25m\] \u\[\e[38;5;25m\]"
#     # Add dir code
#     PS1+="\[\e[48;5;238m\]\[\e[97m\] \w\[\e[0m\]\[\e[38;5;238m\]"

#     if ((exit != 0)); then
#         PS1+="\[\e[48;5;124m\]\[\e[97m\] ${exit}\[\e[0m\]\[\e[38;5;124m\]"
#     else
#         PS1+=''
#     fi
#     PS1+="\[\e[0m\] "
# }

PROMPT_COMMAND=__vlk_bash_prompt_command

__vlk_bash_prompt_command() {
    local retval="$?"
    local jobcount
    jobcount="$(jobs | wc -l)"
    local ps1str="\[\e[0m\e[3;44m\e[1;37m\] \h \[\e[0m\e[3;34m\e[1;47m\] \w "
    local end_icon=]
    local sudo_end_icon=' '
    case "${ICON_TYPE:-}" in
    dashline)
        end_icon=
        ;;
    powerline)
        end_icon=
        ;;
    *)
        sudo_end_icon='#]'
        ;;
    esac
    if sudo -vn &>/dev/null; then
        end_icon="\[\e[0m\e[0;37m\e[0;41m\]$end_icon \[\e[0m\e[0;31m\]$sudo_end_icon"
    else
        end_icon="\[\e[0m\e[0;37m\]$end_icon"
    fi
    ps1str="${ps1str}${end_icon}\[\e[0m\]"
    if ((retval != 0)); then
        ps1str="\[\e[1;37m\e[41m\] $retval $ps1str"
    fi
    if ((jobcount != 0)); then
        ps1str="\[\e[1;30m\e[43m\] $jobcount $ps1str"
    fi
    export PS1="\[\e[0m\]$ps1str "
}

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

if [ -n "${BLE_VERSION:-}" ]; then
    ble-attach
fi
