#!/usr/bin/zsh
set -euo pipefail

d=232
l=255

SHORT_MAX_LEN=4

typeset -A idx=(
    [short]=130
    [sud]=135  [wri]=136  [git]=137  [vim]=138  [lnk]=139
)

typeset -A __DEFAULT__=(
    [color]=
    [txtcolor]=
    [icon]=
    [text]=
    [shorttext]=
)

typeset -A log=(
    [color]=55
    [txtcolor]=$l
    [icon]=󰌆
)

typeset -A dbx=(
    [color]=95
    [txtcolor]=$l
    [icon]=󰆍
    [text]='\$CONTAINER_ID'
    [shorttext]="\${CONTAINER_ID::$SHORT_MAX_LEN}"
)

typeset -A hos=(
    [color]=18
    [txtcolor]=$l
    [icon]=󰟀
    [text]='\$HOSTNAME'
    [shorttext]="\${HOSTNAME::$SHORT_MAX_LEN}"
)

typeset -A con=(
    [color]=40
    [txtcolor]=$d
    [icon]=󱔎
    [text]='\$CONDA_DEFAULT_ENV'
    [shorttext]="\${CONDA_DEFAULT_ENV::$SHORT_MAX_LEN}"
)

typeset -A vev=(
    [color]=220
    [txtcolor]=$d
    [icon]=󰌠
    [text]='\${VIRTUAL_ENV:t}'
    [shorttext]="\${\${VIRTUAL_ENV:t}::$SHORT_MAX_LEN}"
)

typeset -A job=(
    [color]=172
    [txtcolor]=$d
    [icon]=󱜯
    [text]='%j'
)

typeset -A err=(
    [color]=52
    [txtcolor]=$l
    [icon]=󰅗
    [text]='%?'
    [shorttext]='%?'
)

typeset -A pwd=(
    [color]='\$cwd_color'
    [txtcolor]='\$cwd_txtcolor'
    [icon]='\$cwd_icon'
    [text]='%\$((COLUMNS / 2))<..<%~'
    [shorttext]='%\$((COLUMNS / 4))<..<%~'
)

# special
typeset -A sud=(
    [color]=196
    [txtcolor]=$d
    [icon]=󰆥
)

# typeset -A icn=(
#     [cwd_rw]=
#     [cwd_ro]=
#     [git]=󰊢  [vim]=
#     [sud_end]=' '
# )
# typeset -A clr=(
#     [cwd]=33  [lnk]=51  [git]=141  [vim]=120
#     [ps2]=93  [ps3]=89  [ps4_i]=100  [ps4_n]=101
# )

powerline() {
    local idx=$1
    promptparts+=("")
}
typeset -a {short,}promptparts

foreach modulename (log dbx hos con vev job err pwd sud) {
    typeset -A module=("${(@kv)__DEFAULT__}")
    module+=("${(Pkv@)modulename}")
    print -l '' $modulename
    printf '[%s] => %s\n' "${(@kv)module}"
}


BASEPROMPT=
