if [ -z "${ZSH_VERSION:-$BASH_VERSION}" ]; then
    return 1
    exit 1
fi

declare -A vlkprompt

vlkprompt[git_icon]=󰊢
vlkprompt[vim_icon]=
vlkprompt[ro_icon]=
vlkprompt[rw_icon]=
vlkprompt[err_icon]=󰅗
vlkprompt[job_icon]=󱜯
vlkprompt[sud_end_icon]=' '
case "$ICON_TYPE" in
    dashline)
        vlkprompt[end_icon]=
    ;; powerline)
        vlkprompt[end_icon]=
    ;; *)
        vlkprompt[end_icon]=']'
        vlkprompt[git_icon]='G'
        vlkprompt[vim_icon]='V'
        vlkprompt[ro_icon]='-'
        vlkprompt[rw_icon]='.'
        vlkprompt[err_icon]='X'
        vlkprompt[job_icon]='J'
        vlkprompt[sud_end_icon]="${vlkprompt[end_icon]}"
    ;;
esac

vlkprompt[colorterm]="${VLKPROMPT_COLOR_OVERRIDE:-$(tput colors)}"
if ((vlkprompt[colorterm] < 8 )); then
    return
elif ((vlkprompt[colorterm] < 256 )); then
    vlkprompt[light_color]=7
    vlkprompt[dark_color]=0
    vlkprompt[cwd_color]=4
    vlkprompt[git_color]=5
    vlkprompt[vim_color]=2
    vlkprompt[err_color]=1
    vlkprompt[job_color]=3
    vlkprompt[sud_color]=6
    vlkprompt[ps2_color]=5
    vlkprompt[ps3_color]=5
else
    vlkprompt[light_color]=255
    vlkprompt[dark_color]=232
    vlkprompt[cwd_color]=33
    vlkprompt[git_color]=141
    vlkprompt[vim_color]=120
    vlkprompt[err_color]=52
    vlkprompt[job_color]=172
    vlkprompt[sud_color]=196
    vlkprompt[ps2_color]=93
    vlkprompt[ps3_color]=95
fi

if [ -n "${ZSH_VERSION:-}" ]; then # zsh-specific stuff

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git

vlkprompt[sgr]="%k%f%b%u%s"

PS1="${vlkprompt[sgr]}%B%(130V..
)%(0?..%K{${vlkprompt[err_color]}}%F{${vlkprompt[light_color]}}%(130V.. ${vlkprompt[err_icon]}) %? %k%f)\
%(130V..%(1j.%K{${vlkprompt[job_color]}}%F{${vlkprompt[dark_color]}} ${vlkprompt[job_icon]} %j %k%f.))\
%(138V.%K{${vlkprompt[vim_color]}}%F{${vlkprompt[dark_color]}}%(130V.. ${vlkprompt[vim_icon]}) %\$((COLUMNS / 2))<..<%~ %k%f%F{${vlkprompt[vim_color]}}.\
%(137V.%K{${vlkprompt[git_color]}}%F{${vlkprompt[dark_color]}}%(130V.. ${vlkprompt[git_icon]}) %\$((COLUMNS / 2))<..<%~ %k%f%F{${vlkprompt[git_color]}}.\
%K{${vlkprompt[cwd_color]}}%F{${vlkprompt[light_color]}}%(130V.. %(136V.${vlkprompt[rw_icon]}.${vlkprompt[ro_icon]})) %\$((COLUMNS / 2))<..<%~ %k%f%F{${vlkprompt[cwd_color]}}))\
%(135V.%K{${vlkprompt[sud_color]}}${vlkprompt[end_icon]} %k%f%F{${vlkprompt[sud_color]}}${vlkprompt[sud_end_icon]}.%k${vlkprompt[end_icon]})\
${vlkprompt[sgr]} "

PS2="${vlkprompt[sgr]}%B%K{${vlkprompt[ps2_color]}}%F{${vlkprompt[light_color]}} %_ %F{${vlkprompt[ps2_color]}}\
%(135V.%K{${vlkprompt[sud_color]}}${vlkprompt[end_icon]} %k%f%F{${vlkprompt[sud_color]}}${vlkprompt[sud_end_icon]}.%k${vlkprompt[end_icon]})${vlkprompt[sgr]} "

PS3="${vlkprompt[sgr]}%B%K{${vlkprompt[ps3_color]}}%F{${vlkprompt[light_color]}} %_ %F{${vlkprompt[ps3_color]}}\
%(135V.%K{${vlkprompt[sud_color]}}${vlkprompt[end_icon]} %k%f%F{${vlkprompt[sud_color]}}${vlkprompt[sud_end_icon]}.%k${vlkprompt[end_icon]})${vlkprompt[sgr]} "

SUDO_PROMPT="$(print -P "${vlkprompt[sgr]}%B%K{${vlkprompt[sud_color]}}%F{${vlkprompt[light_color]}} password %k%F{${vlkprompt[sud_color]}}${vlkprompt[sud_end_icon]}${vlkprompt[sgr]}") "

unset vlkprompt

__vlk_precmd () {
    if sudo -vn &>/dev/null; then # sudo
        psvar[135]=1
    else
        psvar[135]=''
    fi
    if [ -w "$PWD" ]; then # dir icon
        psvar[136]=1
    else
        psvar[136]=''
    fi
    vcs_info &>/dev/null
    if [ -n "${vcs_info_msg_0_:-}" ]; then # git color
        psvar[137]=1
    else
        psvar[137]=''
    fi
    psvar[138]='' # vicmd
}
export -U precmd_functions
precmd_functions+=('__vlk_precmd')

function zle-line-init zle-keymap-select {
    if [[ "$KEYMAP" == vicmd ]]; then
        psvar[138]=1
    else
        psvar[138]=''
    fi
    zle reset-prompt
}
zle -N zle-keymap-select

__vlk-zle-line-init () {
    [[ "$CONTEXT" == 'start' ]] || return 0
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[1]
    zle recursive-edit
    local -i ret=$?
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[2]
    if [[ "$ret" == 0 && "$KEYS" == $'\4' ]]; then
        psvar[130]=1
        zle reset-prompt
        exit
    fi
    psvar[130]=1
    zle reset-prompt
    psvar[130]=''
    if (( ret )); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}

zle -N zle-line-init __vlk-zle-line-init

elif [ -n "${BASH_VERSION:-}" ]; then # bash-specific stuff

PROMPT_COMMAND=__vlk_bash_prompt_command
__vlk_bash_prompt_command() {
    local retval="$?"
    local jobcount="$(jobs | wc -l)"
    local ps1str="\[\e[0m\e[3;44m\e[1;37m\] \h \[\e[0m\e[3;34m\e[1;47m\] \w "
    local end_icon=']'
    local sudo_end_icon=' '
    case "${ICON_TYPE:-}" in
    dashline) end_icon='' ;;
    powerline) end_icon='' ;;
    *) sudo_end_icon='#]' ;;
    esac
    local computed_end_icon="\[\e[0m\e[0;37m\]$end_icon"
    sudo -vn &>/dev/null && computed_end_icon="\[\e[0m\e[0;37m\e[0;41m\]$end_icon \[\e[0m\e[0;31m\]$sudo_end_icon"
    ps1str="${ps1str}${computed_end_icon}\[\e[0m\]"
    ((retval != 0)) && ps1str="\[\e[1;37m\e[41m\] $retval $ps1str"
    ((jobcount != 0)) && ps1str="\[\e[1;30m\e[43m\] $jobcount $ps1str"
    export PS1="\[\e[0m\]$ps1str "
}

fi
