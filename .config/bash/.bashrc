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
    "$HOME/bin/vlkrc"; do
    [ -f "$i" ] && . "$i"
done
unset i

HISTFILE="$XDG_STATE_HOME/bash_history"
HISTCONTROL=erasedups:ignoreboth

. ~/.config/zsh/rc.d/40-prompt.zsh

# PROMPT_COMMAND=__vlk_bash_prompt_command
# __vlk_bash_prompt_command() {
#     local retval="$?"
#     local jobcount="$(jobs | wc -l)"
#     local ps1str="\[\e[0m\e[3;44m\e[1;37m\] \h \[\e[0m\e[3;34m\e[1;47m\] \w "
#     local end_icon=']'
#     local sudo_end_icon=' '
#     case "${ICON_TYPE:-}" in
#     dashline) end_icon='' ;;
#     powerline) end_icon='' ;;
#     *) sudo_end_icon='#]' ;;
#     esac
#     local computed_end_icon="\[\e[0m\e[0;37m\]$end_icon"
#     sudo -vn &>/dev/null && computed_end_icon="\[\e[0m\e[0;37m\e[0;41m\]$end_icon \[\e[0m\e[0;31m\]$sudo_end_icon"
#     ps1str="${ps1str}${computed_end_icon}\[\e[0m\]"
#     ((retval != 0)) && ps1str="\[\e[1;37m\e[41m\] $retval $ps1str"
#     ((jobcount != 0)) && ps1str="\[\e[1;30m\e[43m\] $jobcount $ps1str"
#     export PS1="\[\e[0m\]$ps1str "
# }

if command -v figlet &>/dev/null; then
    printf '%s -%s' "${0##*/}" "$-" | figlet -f smslant -w "$COLUMNS" | (command -v lolcadt &>/dev/null && lolcat || :)
fi
