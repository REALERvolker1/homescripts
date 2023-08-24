if [[ "$ICON_TYPE" == 'fallback' ]] || [ ! -x =vlkprompt ]; then
    return
fi

return

case "$ICON_TYPE" in
    dashline)
        export VLKPROMPT_END_CHAR=
    ;; powerline)
        export VLKPROMPT_END_CHAR=
    ;; *)
        export VLKPROMPT_END_CHAR='>'
    ;;
esac

__vlk_precmd_func () {
    printf '\033[5 q'
    export VLKPROMPT_RETVAL="$?"
    export VLKPROMPT_JOB_COUNT="$(jobs | wc -l)"
    unset VLKPROMPT_KEYMAP VLKPROMPT_SUDO
    sudo -vn &>/dev/null && export VLKPROMPT_SUDO='ye'
}
export -U precmd_functions
precmd_functions+=('__vlk_precmd_func')

function zle-line-init zle-keymap-select {
    [[ "$KEYMAP" == vicmd ]] && export VLKPROMPT_KEYMAP=vicmd || unset VLKPROMPT_KEYMAP
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
        _vlk_prompt_compact=1
        zle reset-prompt
        exit
    fi
    _vlk_prompt_compact=1
    zle reset-prompt
    unset _vlk_prompt_compact
    if (( ret )); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}

zle -N zle-line-init __vlk-zle-line-init

__vlk_prompt_command () {
    local vlkp
    vlkp="$(vlkprompt)"
    if (( $_vlk_prompt_compact )); then
        echo "%k%f%b%u%s$vlkp"
    else
        echo "%k%f%b%u%s
$vlkp"
    fi
}
PS1='$(__vlk_prompt_command) '
#PS1='%k%f%b%u%s
#$(vlkprompt) '

PS2="%k%f%b%u%s%B%K{93} %_ %(135V.%K{196}%F{93}$VLKPROMPT_END_CHAR %k%F{196}$VLKPROMPT_END_CHAR%f.%k%F{93}$VLKPROMPT_END_CHAR%f)%k%f%b%u%s "
PS3="%k%f%b%u%s%B%K{95} ?# %(135V.%K{196}%F{95}$VLKPROMPT_END_CHAR %k%F{196}$VLKPROMPT_END_CHAR%f.%k%F{95}$VLKPROMPT_END_CHAR%f)%k%f%b%u%s "

SUDO_PROMPT="$(print -P "%B%K{196} password %k%F{196} %b%f") "
