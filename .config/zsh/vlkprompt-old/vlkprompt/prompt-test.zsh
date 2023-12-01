#!/bin/zsh

# PS1='$hello${hh}$world '

declare -A vlkprompt_col vlkprompt

vlkprompt_col[cwd]=33
vlkprompt_col[git]=141
vlkprompt_col[vim]=120
vlkprompt_col[err]=52
vlkprompt_col[job]=172
vlkprompt_col[hos]=18
vlkprompt_col[sud]=196
vlkprompt_col[ps2]=93
vlkprompt_col[ps3]=89

vlkprompt[sgr]='%k%f%b%u%s'
PROMPT_TRANSIENT=false

__precmd_dir() {
    # start with directory
    if git status &>/dev/null; then
        vlkprompt[cwd_color]="${vlkprompt_col[git]}"
        vlkprompt[cwd_icon]=󰊢
    else
        vlkprompt[cwd_color]="${vlkprompt_col[cwd]}"
        if [[ -w "$PWD" ]]; then
            vlkprompt[cwd_icon]=
        else
            vlkprompt[cwd_icon]=
        fi
    fi
}
__precmd_end() {
    if sudo -vn &>/dev/null; then
        vlkprompt[end]="%K{${vlkprompt_col[sud]}}%F{${vlkprompt[cwd_color]}}"
    else
    fi
}

export -U precmd_functions=(__precmd_dir __precmd_end)
