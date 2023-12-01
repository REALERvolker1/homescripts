#!/usr/bin/zsh
[[ "$-" == *i* && -z $BASH_VERSION && $TERM != linux && -z ${VLKPROMPT_SKIP:-} ]] || {
    return 1
    exit 1
}

typeset -AU VLK_COLORS=(
    [l]=255  [d]=232
    [cwd]=33  [lnk]=51  [git]=141  [vim]=120
    [err]=52  [job]=172  [tim]=226
    [dbx]=96  [hos]=18  [log]=55
    [con]=40  [vev]=220
    [ps2]=93  [ps3]=89  [ps4_i]=100  [ps4_n]=101
    [sud]=196
)
typeset -AU VLK_ICONS=(
    [cwd_ro]=   [cwd_rw]=
    [git]=󰊢  [vim]=
    [err]=󰅗  [job]=󱜯  [tim]=󱑃
    [dbx]=󰆍  [hos]=󰟀  [log]=󰌆
    [con]=󱔎  [vev]=󰌠
    [sud]=󰆥 [sud_end]=' '
    [end]=  [end_r]=
)

unsetopt single_line_zle
setopt prompt_subst

# needed for proper python venv string
export VIRTUAL_ENV_DISABLE_PROMPT=1

typeset -A __vlkprompt_internal

typeset -aU prompt_segments
typeset -aU precmd_functions

if [[ $- == *l* ]]; then
    prompt_segments+=("[1;48;5;${VLK_COLORS[log]};38;5;${VLK_COLORS[l]}m ${VLK_ICONS[log]} [0;38;5;${VLK_COLORS[log]}m")
fi

if [[ $HOSTNAME != $CURRENT_HOSTNAME ]]; then
    if [[ -n ${CONTAINER_ID-} ]]; then
        hostcol=$VLK_COLORS[dbx]
        hosttxt="${CONTAINER_ID-}"
    else
        hostcol=$VLK_COLORS[hos]
        # '%' means the end of the variable. This escapes it
        hosttxt="${HOSTNAME//\%/%%}"
    fi
    prompt_segments+=("[1;48;5;${hostcol};38;5;${VLK_COLORS[l]}m ${hosttxt} [0;38;5;${hostcol}m")
    unset hostcol hosttxt
fi

prompt_segments+=()

if command -v conda &>/dev/null; then
    __vlkprompt::precmd::conda() {
        [[ -n \${CONDA_DEFAULT_ENV-} ]] &&
            __vlkprompt_internal[conda_str]="[48;5;${VLK_COLORS[con]}m${VLK_ICONS[end]}[1;38;5;${VLK_COLORS[d]}m ${VLK_ICONS[con]} \${CONDA_DEFAULT_ENV-} [0;38;5;${VLK_COLORS[con]}m"
    }
    precmd_functions+=('__vlkprompt::precmd::conda')
    prompt_segments+=('${__vlkprompt_internal[conda_str]}')
fi

__vlkprompt::precmd::pyvenv() {
    [[ -n \${VIRTUAL_ENV-} ]] &&
        __vlkprompt_internal[conda_str]="[48;5;${VLK_COLORS[vev]}m${VLK_ICONS[end]}[1;38;5;${VLK_COLORS[d]}m ${VLK_ICONS[vev]} \${VIRTUAL_ENV-} [0;38;5;${VLK_COLORS[vev]}m"
}
precmd_functions+=('__vlkprompt::precmd::pyvenv')

PROMPT="[0m
${(j..)prompt_segments}\${__vlkprompt_internal[end_icon]}[0m "

unset prompt_segments
__vlkprompt_internal[end_icon]=$VLK_ICONS[end]
