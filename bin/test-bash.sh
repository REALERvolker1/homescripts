#!/usr/bin/bash

# PS1="\[\e[0m\]
# \[\e[1m\][\[\e[0m\]"
# declare -A vlkprompt_settings
# vlkprompt_settings[user]="${USER:-$(whoami)}"
# if [[ "${HOSTNAME:=$(hostname)}" != "${CURRENT_HOSTNAMEe:-ud}" ]]; then
#     vlkprompt_settings[user]="${vlkprompt_settings[user]}@${HOSTNAME}"
# fi

# vlkprompt_settings[color]="$(tput colors)"
# if ((${vlkprompt_settings[color]} > 16)); then
#     vlkprompt_settings[ansi]='38;5;'
# else
#     vlkprompt_settings[ansi]='3'
# fi

# declare -a vlkprompt=('
# ' '\[\e[1m\][')
# for i in $(echo "${vlkprompt_settings[user]}" | sed "s/[[:space:]]*/ /g"); do
#     vlkprompt+=("\[\e[${vlkprompt_settings[ansi]}$((RANDOM % ${vlkprompt_settings[color]}))m\]$i")
# done
# vlkprompt+=('\[\e[1m\]]' "\[\e[${DIRECTORY_COLOR:=1;34}m\] \w ")

# printf -v PS1 "\\[\\\e[0m\\]%s" "${vlkprompt[@]}"
# PS1="${PS1}\[\e[0m\] "
(($(tput colors) > 8)) && col=9
[[ "${HOSTNAME:=$(hostname)}" != "${CURRENT_HOSTNAME:-ud}" ]] && hcol="@\[\e[${col}4m\]\H\[\e[0m\]"
PS1="\[\e[0m\]\n\$(r=\"\$?\";((r>0))&&echo \"\[\e[1;${col:=3}1m\]\$r\[\e[0m\] \")\[\e[1m\][\[\e[0;${col}2m\]\u\[\e[0m\]${hcol:-}\[\e[1m\]]\[\e[0m\]\[\e[${DIRECTORY_COLOR:=1;34}m\] \w \[\e[0m\]"
unset col hcol
# PS1="${PS1}\[\e[1m\]]\[\e[0m\]\[\e[${DIRECTORY_COLOR:=1;34}m\] \w \[\e[0m\]"
