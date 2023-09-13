

pub const INIT_PRECMD_SCRIPT_BASH: &str = "__vlkprompt_precmd () {
    export VLKPROMPT_ERR=\"$?\"
    export VLKPROMPT_JOBS=\"$(jobs | wc -l)\"
    export VLKPROMPT_SUDO=\"$(sudo -vn &>/dev/null && echo true)\"
    export VLKPROMPT_GIT=\"$(git status &>/dev/null && echo true)\"
    export VLKPROMPT_VIM=''
    export VLKPROMPT_TRANSIENT=''
}";

pub const INIT_PRECMD_SCRIPT_ZSH: &str = "__vlkprompt_precmd () {
    export VLKPROMPT_ERR=\"$?\"
    export VLKPROMPT_JOBS=\"$(jobs | wc -l)\"
    export VLKPROMPT_SUDO=\"$(sudo -vn &>/dev/null && echo true)\"
    export VLKPROMPT_GIT=\"$(git status &>/dev/null && echo true)\"
    export VLKPROMPT_NAMED_DIRS=\"$(hash -d)\"
    export VLKPROMPT_VIM=''
    export VLKPROMPT_TRANSIENT=''
}";

/*
export VLKPROMPT_SUDO=\"$(
        if sudo -vn &>/dev/null; then
            echo true
        else
            echo false
        fi
    )\"
    export VLKPROMPT_GIT=\"$(
        if git status &>/dev/null; then
            echo true
        else
            echo false
        fi
    )\"
*/

pub const INIT_ZSH_SCRIPT: &str = "export -U precmd_functions
precmd_functions+=('__vlkprompt_precmd')

# I have no idea why this works, I'm just not gonna question it
function zle-line-init zle-keymap-select {
    if [[ \"$KEYMAP\" == vicmd ]]; then
        export VLKPROMPT_VIM=true
    else
        export VLKPROMPT_VIM=''
    fi
    zle reset-prompt
}
__vlkprompt_zle-line-init () {
    [[ \"$CONTEXT\" == 'start' ]] || return 0
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[1]
    zle recursive-edit
    local -i ret=$?
    (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[2]
    if [[ \"$ret\" == 0 && \"$KEYS\" == $'\\4' ]]; then
        export VLKPROMPT_TRANSIENT=true
        zle reset-prompt
        exit
    fi
    VLKPROMPT_TRANSIENT=true
    zle reset-prompt
    export VLKPROMPT_TRANSIENT=''
    if (( ret )); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}
";
