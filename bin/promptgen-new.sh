#!/usr/bin/zsh
# a script that generates my zsh prompt stuff
emulate -LR zsh
set -euo pipefail
IFS=$'\n\t'

# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

# dependency check
declare -a faildeps=()
for i in zsh git; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

typeset -A idx=(
    [short]=130
    [con]=132
    [vev]=133
    [tim]=134
    [sud]=135
    [wri]=136
    [git]=137
    [vim]=138
    [lnk]=139
)

typeset -A clr=(
    [l]=255
    [d]=232
    \
    [cwd]=33
    [lnk]=51
    [git]=141
    [vim]=120
    \
    [err]=52
    [job]=172
    [tim]=226
    \
    [dbx]=95
    [hos]=18
    [log]=55
    \
    [con]=40
    [vev]=220
    \
    [ps2]=93
    [ps3]=89
    [ps4_i]=100
    [ps4_n]=101
    \
    [sud]=196
)

typeset -A icn=(
    [cwd]="%(${idx[wri]}V..)"
    [git]=󰊢
    [vim]=
    \
    [err]=󰅗
    [job]=󱜯
    [tim]=󱑃
    \
    [dbx]=󰆍
    [hos]=󰟀
    [log]=󰌆
    \
    [con]=󱔎
    [vev]=󰌠
    \
    [sud_end]=' '
)

typeset -A set=(
    [end]=
    [end_r]=
    [sgr]='[0m'
)

typeset -A strn=(
    [pwd]='%\$((COLUMNS / 2))<..<%~'
    [err]='%?'
    [job]='%j'
    [tim]='\${__vlkprompt_internal[timer_str]}'
    [vev]='\${__vlkprompt_internal[venv_str]}'
    [con]='\${__vlkprompt_internal[conda_str]}'
    [dbx]='${CONTAINER_ID-}'
    [hos]="%(${idx[short]}V.%m.%M)"
)

# fmt_segment() {
#     local i i_val bgcolor txtcolor conditional contentstr icon cond_content_true cond_content_false
#     local endicon=$set[end]
#     for i in "$@"; do
#         i_val="${i#*=}"
#         case "${i:-}" in
#         -bg=*) bgcolor="$i_val" ;;
#         -tx=*) txtcolor="$i_val" ;;
#         -icn=*) icon="$i_val" ;;
#         -cond=*) conditional="$i_val" ;;
#         -cond-false=*) cond_false="$i_val" ;;
#         -cond-true=*) cond_true="$i_val" ;;
#         -right) endicon=$set[end_r] ;;
#         esac
#     done
#     icon="${${icon:+ $icon }:-}" # either '  ' or ' '
#     txtcolor="[1;38;5;${txtcolor}m"
#     if [[ -n $short_content ]]; then

#     else

#     fi
#     contentstr="${contentstr} [0;38;5;${bgcolor}m"
#     if [[ -n $conditional ]]; then
#         if [[ $conditional == "${idx[short]}V" ]]; then
#             contentstr="%(${idx[short]}V.$txtcolor $cond_true.${set[end]}$txtcolor${icon}$cond_false)"
#         else
#             contentstr="%(${conditional}.%(${idx[short]}V.$txtcolor .${set[end]}$txtcolor${icon})$cond_true.$cond_false)"
#         fi
#         # %(cond.true.false)
#         # if ((conditional_is_false)); then
#         #     # %(cond..content)
#         #     conditional="${conditional}."
#         # else
#         #     # %(cond.content.)
#         #     contentstr="${contentstr}."
#         # fi
#         contentstr="%(${conditional}.${contentstr})"
#     fi
#     print "[48;5;${bgcolor}m${contentstr}"
# }
# fmt_segment -bg=$clr[git] -tx=$clr[d] -cond=$idx[git]'V' -long='%~' -icn=$icn[git]

fmt_segment() {
    local i i_val bgcolor txtcolor contentstr content short_content
    local endicon=$set[end]
    for i in "$@"; do
        i_val="${i#*=}"
        case "${i:-}" in
        -bg=*) bgcolor="$i_val" ;;
        -tx=*) txtcolor="$i_val" ;;
        -icn=*) icon="$i_val" ;;
        -short-content=*) short_content="$i_val" ;;
        *) content="$i" ;;
        esac
    done
    icon="${${icon:+$icon }:-}" # either ' ' or ''
    txtcolor="[1;38;5;${txtcolor}m"
    if [[ -n ${short_content:=} ]]; then

        # contentstr="${contentstr}%(${idx[short]}V.$txtcolor $short_content.${set[end]}$txtcolor $icon)"
    fi
    # if it is short, then it prints just the text color, followed by any short-specific content.
    # Otherwise, it prints the end icon, the textcolor, and the icon. If
    # It prints the end icon because the previous module gave it its color. It gives its fg color to the next module to color in.
    # If there was any short content, then it will print the long content only if it is in long mode.
    # Otherwise, it checks for short content, and if there is none, then it will just print content regardless.
    print "[48;5;${bgcolor}m%(${idx[short]}V.$txtcolor ${short_content:-}.${set[end]}$txtcolor $icon${short_content:+$content})${${short_content:+}:-$content} [0;38;5;${bgcolor}m"
}

typeset -A contents=(
    [log]="$(fmt_segment -bg=$clr[log] -tx=$clr[l] $icn[log])"
    [pwd]='\${__vlkprompt_internal[pwd_str]}'
    [cwd]="$(fmt_segment -bg=$clr[cwd] -tx=$clr[l] -icn=$icn[cwd] $strn[pwd])"
    [lnk]="$(fmt_segment -bg=$clr[lnk] -tx=$clr[d] -icn=$icn[cwd] $strn[pwd])"
    [git]="$(fmt_segment -bg=$clr[git] -tx=$clr[d] -icn=$icn[git] $strn[pwd])"
    [vim]="$(fmt_segment -bg=$clr[vim] -tx=$clr[d] -icn=$icn[vim] $strn[pwd])"
    # [hos]="$(fmt_segment -bg=$clr[hos] -tx=$clr[l] -icn=$icn[hos] $strn[hos])"
    [sud]="%(${idx[sud]}V.[48;5;${clr[sud]}m%(${idx[short]}V..${set[end]} )[0;38;5;${clr[sud]}m${icn[sud_end]}.${set[end]})"
)

foreach i (err:l job:d tim:d vev:d con:d hos:l dbx:l) {
    key="${i%:*}"
    txt="${i##*:}"
    contents[$key]="$(fmt_segment -bg=$clr[$key] -tx=$clr[$txt] -icn=$icn[$key] $strn[$key])"
}

contents[err]="%(0?..${contents[err]})"
contents[job]="%(1j.${contents[job]}.)"
contents[tim]="%(${idx[tim]}V.${contents[tim]}.)"
contents[vev]="%(${idx[vev]}V.${contents[vev]}.)"
contents[con]="%(${idx[con]}V.${contents[con]}.)"

if ! command -v conda &>/dev/null; then
    echo "command 'conda' not found. Removing from prompt"
fi
if ! command -v pip &>/dev/null; then
    echo "command 'pip' not found. Removing from prompt"
fi

echo "
typeset -a EXTRA=()
if [[ -n \${CONTAINER_ID-} || \${HOSTNAME-} != \${CURRENT_HOSTNAME-} || \$- == *l* ]] {
    [[ \$- == *l* ]] && EXTRA+=(\"${contents[log]}\")
    if [[ -n \${CONTAINER_ID-} ]]; then
        EXTRA+=(\"${contents[dbx]}\")
    else
        EXTRA+=(\"${contents[hos]}\")
    fi
}
PROMPT=\"${set[sgr]}%(${idx[short]}V..
)\${(j..)EXTRA}${contents[con]}${contents[cwd]}\"
"

printf "\e[0m[%s] => %s${set[end]}\e[0m\n" "${(@kv)contents}"
