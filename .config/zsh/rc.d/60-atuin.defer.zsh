command -v atuin &>/dev/null || return
autoload -U add-zsh-hook
export ATUIN_SESSION=$(atuin uuid)
export ATUIN_HISTORY="atuin history list"
_atuin_preexec() {
    local id
    id=$(atuin history start -- "$1")
    export ATUIN_HISTORY_ID="$id"
}
_atuin_precmd() {
    local EXIT="$?"
    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return
    (RUST_LOG=error atuin history end --exit $EXIT -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
}
_atuin_search() {
    emulate -L zsh
    zle -I
    output=$(RUST_LOG=error atuin search $* -i -- $BUFFER 3>&1 1>&2 2>&3)
    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output
    fi
    zle reset-prompt
}
_atuin_up_search() {
    _atuin_search --shell-up-key-binding
}
add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search
bindkey '^r' _atuin_search_widget
bindkey '^[[A' _atuin_up_search_widget
bindkey '^[OA' _atuin_up_search_widget