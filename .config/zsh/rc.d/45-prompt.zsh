[[ "$-" == *i* && -z $BASH_VERSION && $TERM != linux ]] || {
    return 1
    exit 1
}

command_not_found_handler() {
    echo -e "\e[0;1;48;5;196;38;5;232m 󰅗 ERROR \e[0;38;5;196;48;5;52m \e[38;5;255mCommand '\e[1m${1:-}\e[0;48;5;52;38;5;255m' not found \e[0;38;5;52m\e[0m"
    return 127
}

if [[ "$HOSTNAME" != "$CURRENT_HOSTNAME" ]] && [[ "$-" =~ l ]]; then
    HOSTSTR="%k%f%b%u%s%K{18}%B%F{255} %(130V.%m.%M) %k%f%b%u%s%(130V..%F{18}%K{93})%k%f%b%u%s%K{93}%B%F{255}%(130V.. 󰌆) %k%f%b%u%s%(130V..%F{93}%(134V.%K{226}.%(1j.%K{172}.%(0?.%(138V.%K{120}.%(137V.%K{141}.%K{33})).%K{52}))))"
elif [[ "$-" =~ l ]]; then
    HOSTSTR="%k%f%b%u%s%K{93}%B%F{255}%(130V.. 󰌆) %k%f%b%u%s%(130V..%F{93}%(134V.%K{226}.%(1j.%K{172}.%(0?.%(138V.%K{120}.%(137V.%K{141}.%K{33})).%K{52}))))"
elif [[ "$HOSTNAME" != "$CURRENT_HOSTNAME" ]]; then
    HOSTSTR="%k%f%b%u%s%K{18}%B%F{255} %(130V.%m.%M) %k%f%b%u%s%(130V..%F{18}%(134V.%K{226}.%(1j.%K{172}.%(0?.%(138V.%K{120}.%(137V.%K{141}.%K{33})).%K{52}))))"
fi
PROMPT="%k%f%b%u%s%(130V..
)${HOSTSTR}%(134V.%k%f%b%u%s%K{226}%B%F{232}%(130V.. 󱑃) \$VLKPROMPT_CMD_TIMER_STR %k%f%b%u%s.)%(130V..%(134V.%F{226}%(1j.%K{172}.%(0?.%(138V.%K{120}.%(137V.%K{141}.%K{33})).%K{52})).))%(1j.%k%f%b%u%s%K{172}%B%F{232}%(130V.. 󱜯) %j %k%f%b%u%s.)%(130V..%(1j.%F{172}%(0?.%(138V.%K{120}.%(137V.%K{141}.%K{33})).%K{52}).))%(0?..%k%f%b%u%s%K{52}%B%F{255}%(130V.. 󰅗) %? %k%f%b%u%s)%(130V..%(0?..%F{52}%(138V.%K{120}.%(137V.%K{141}.%K{33}))))%k%f%b%u%s%(138V.%K{120}%B%F{232}%(130V.. ).%(137V.%K{141}%B%F{232}%(130V.. 󰊢).%K{33}%B%F{255}%(130V.. %(136V..)))) %\$((COLUMNS / 2))<..<%~ %k%f%b%u%s%(135V.%K{196}.)%(138V.%F{120}.%(137V.%F{141}.%F{33}))%k%f%b%u%s%(135V.%k%f%b%u%s%K{196} %k%f%b%u%s%F{196} %k%f%b%u%s.) "

PS2="%k%f%b%u%s%K{93}%B%F{255} %_ %k%f%b%u%s%F{93}%(135V.%K{196} %k%f%b%u%s%F{196} .)%k%f%b%u%s"
PS3="%k%f%b%u%s%K{89}%B%F{255} %_ %k%f%b%u%s%F{89}%(135V.%K{196} %k%f%b%u%s%F{196} .)%k%f%b%u%s"

SUDO_PROMPT=$'\e[1;48;5;196;38;5;255m entering sudo mode \e[0;38;5;196m  \e[0m'
# PROMPT FUNCTIONS
declare GIT_PRECMD_PREV_PWD GIT_PRECMD_PWD GIT_PRECMD_PWD_WRITABLE GIT_PRECMD_PWD_GIT
declare -i OLDSECS=0

__vlkprompt_precmd() {
    local -i timer=$((SECONDS - OLDSECS))
    VLKPROMPT_CMD_TIMER_STR=
    if ((timer > 14)); then
        local leading_zero timedisp timedisp_sm
        if ((timer > 60)); then
            local -i hour=$((timer / 3600))
            local -i min=$(($((timer % 3600)) / 60))
            local -i sec=$((timer % 60))

            if ((hour > 0)); then
                timedisp="${timedisp}${hour}h "
                timedisp_sm="${timedisp_sm}${hour}:"
                ((min < 10)) && leading_zero=0
            fi
            if ((min > 0)); then
                timedisp="${timedisp}${min}m "
                timedisp_sm="${timedisp_sm}${leading_zero:-}${min}:"
                ((sec < 10)) && leading_zero=0
            fi
            if ((sec > 0)); then
                timedisp="${timedisp}${sec}s "
                timedisp_sm="${timedisp_sm}${leading_zero:-}${sec}:"
            fi
            timedisp="${timedisp%* }"
            timedisp_sm="${timedisp_sm%*:}"
        else
            timedisp="${timer}s"
            timedisp_sm="${timer}"
        fi
        psvar[134]=1
        VLKPROMPT_CMD_TIMER_STR="%(130V.${timedisp_sm}.${timedisp})"
    fi
    if [[ $PWD == $GIT_PRECMD_PWD ]]; then
        psvar[136]="$GIT_PRECMD_PWD_WRITABLE"
        psvar[137]="$GIT_PRECMD_PWD_GIT"
        return
    elif [[ $PWD == $GIT_PRECMD_PREV_PWD ]]; then
        psvar[137]=1
    elif git status &>/dev/null; then
        GIT_PRECMD_PREV_PWD="$PWD"
        psvar[137]=1
    elif [[ -w $PWD ]]; then
        psvar[136]=1
    fi
    GIT_PRECMD_PWD="$PWD"
    GIT_PRECMD_PWD_GIT="${psvar[137]}"
    GIT_PRECMD_PWD_WRITABLE="${psvar[136]}"
}
[[ -z ${DISTROBOX_ENTER_PATH:-} ]] && __vlkprompt_sudo_cmd() { sudo -vn &>/dev/null && psvar[135]=1; }

export -U precmd_functions=('__vlkprompt_precmd' '__vlkprompt_sudo_cmd')


function zle-line-init zle-keymap-select {
    if [[ $KEYMAP == vicmd ]]; then
        psvar[138]=1
    else
        psvar[138]=
    fi
    zle reset-prompt
}
zle -N zle-keymap-select

__vlk-zle-line-init() {
    [[ $CONTEXT == start ]] || return 0
    (($+zle_bracketed_paste)) && print -r -n - "${zle_bracketed_paste[1]}"
    zle recursive-edit
    local -i ret=$?
    (($+zle_bracketed_paste)) && print -r -n - "${zle_bracketed_paste[2]}"
    if [[ $ret == 0 && $KEYS == $'\4' ]]; then
        psvar[130]=1
        zle reset-prompt
        exit
    fi
    psvar[130]=1
    zle reset-prompt
    psvar=()
    OLDSECS=$SECONDS
    VLKPROMPT_CMD_TIMER_STR=
    if ((ret)); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}

zle -N zle-line-init __vlk-zle-line-init
