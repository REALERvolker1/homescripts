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
            if [ -f "$i" ]; then
                . "$i" $__bleargs
                break
            fi
        done
        unset i __bleargs
    fi
fi

[ -f "$HOME/bin/vlkrc" ] && . "$HOME/bin/vlkrc"

HISTFILE="$XDG_STATE_HOME/bash_history"
export HISTCONTROL=erasedups:ignoreboth

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
