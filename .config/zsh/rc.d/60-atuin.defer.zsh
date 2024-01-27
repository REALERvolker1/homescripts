[[ ${VLKZSH_SAFEMODE:-1} -eq 0 && $+commands[atuin] -eq 1 && -z ${VLKATUIN_SKIP-} ]] || return

# This is my edited and abridged version of Atuin's init script
export ATUIN_SESSION="$(atuin uuid)"
__atuin::preexec() {
    local id
    id="$(atuin history start -- "${1-}")"
    export ATUIN_HISTORY_ID=${id-}
}

__atuin::precmd() {
    [[ -z ${ATUIN_HISTORY_ID-} ]] && return
    local -i EXIT=$?
    (ATUIN_LOG=error atuin history end --exit $EXIT -- $ATUIN_HISTORY_ID &) &>/dev/null
    export ATUIN_HISTORY_ID=
}

__atuin::zle::search() {
    emulate -L zsh
    zle -I
    local output
    output=$(ATUIN_SHELL_ZSH=t ATUIN_LOG=error atuin search $* -i -- ${BUFFER-} 3>&1 1>&2 2>&3)
    zle reset-prompt
    if [[ -n ${output-} ]]; then
        RBUFFER=
        LBUFFER=$output
    fi
    if [[ ${LBUFFER-} == __atuin_accept__:* ]]
    then
        LBUFFER=${LBUFFER#__atuin_accept__:}
        zle accept-line
    fi
}
__atuin::zle::up_search() __atuin::zle::search --shell-up-key-binding

preexec_functions+=('__atuin::preexec')
precmd_functions+=('__atuin::precmd')
zle -N _atuin_search_widget __atuin::zle::search
zle -N _atuin_up_search_widget __atuin::zle::up_search
bindkey '^r' _atuin_search_widget
bindkey '^[[A' _atuin_up_search_widget
bindkey '^[OA' _atuin_up_search_widget
