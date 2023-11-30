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
    [short]=130  [con]=132  [vev]=133  [tim]=134
    [sud]=135  [wri]=136  [git]=137  [vim]=138  [lnk]=139
)

typeset -A clr=(
    [l]=255  [d]=232
    [cwd]=33  [lnk]=51  [git]=141  [vim]=120
    [err]=52  [job]=172  [tim]=226
    [dbx]=95  [hos]=18  [log]=55
    [con]=40  [vev]=220
    [ps2]=93  [ps3]=89  [ps4_i]=100  [ps4_n]=101
    [sud]=196
)

typeset -A icn=(
    [cwd]="%(${idx[wri]}V..)"
    [git]=󰊢  [vim]=
    [err]=󰅗  [job]=󱜯  [tim]=󱑃
    [dbx]=󰆍  [hos]=󰟀  [log]=󰌆
    [con]=󱔎  [vev]=󰌠
    [sud]=󰆥 [sud_end]=' '
)

typeset -A set=( [end]=  [end_r]=  [sgr]='[0m' )

typeset -A strn=(
    [pwd]='%\$((COLUMNS / 2))<..<%~'
    [err]='%?'
    [job]='%j'
    [vev]='\${__vlkprompt_internal[venv_str]}'
    [con]='\${__vlkprompt_internal[conda_str]}'
    [dbx]='${CONTAINER_ID-}'
    [hos]="%(${idx[short]}V.%m.%M)"
)

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
    [tim]="$(fmt_segment -bg=$clr[tim] -tx=$clr[d] -icn=$icn[tim] -short-content='\${__vlkprompt_internal[timer_str_small]}' '\${__vlkprompt_internal[timer_str]}')"
    [log]="$(fmt_segment -bg=$clr[log] -tx=$clr[l] $icn[log])"
    [cwd]="$(fmt_segment -bg=$clr[cwd] -tx=$clr[l] -icn=$icn[cwd] $strn[pwd])"
    [lnk]="$(fmt_segment -bg=$clr[lnk] -tx=$clr[d] -icn=$icn[cwd] $strn[pwd])"
    [git]="$(fmt_segment -bg=$clr[git] -tx=$clr[d] -icn=$icn[git] $strn[pwd])"
    [vim]="$(fmt_segment -bg=$clr[vim] -tx=$clr[d] -icn=$icn[vim] $strn[pwd])"
    # [hos]="$(fmt_segment -bg=$clr[hos] -tx=$clr[l] -icn=$icn[hos] $strn[hos])"
    [sud]="%(${idx[sud]}V.[48;5;${clr[sud]}m%(${idx[short]}V..${set[end]} )[0;38;5;${clr[sud]}m${icn[sud_end]}.${set[end]})"
)

typeset -A right_contents=(
    [git]=
)

foreach i (err:l job:d vev:d con:d hos:l dbx:l) {
    key="${i%:*}"
    txt="${i##*:}"
    contents[$key]="$(fmt_segment -bg=$clr[$key] -tx=$clr[$txt] -icn=$icn[$key] $strn[$key])"
}

contents[err]="%(0?..${contents[err]})"
contents[job]="%(1j.${contents[job]}.)"
contents[tim]="%(${idx[tim]}V.${contents[tim]}.)"
contents[con]="%(${idx[con]}V.${contents[con]}.)"
contents[vev]="%(${idx[vev]}V.${contents[vev]}.)"

contents[pwd]="%(${idx[vim]}V.${contents[vim]}.\\\${__vlkprompt_internal[pwd_str]})"

declare -A precmds promptwidgets promptparts

timefmt_ucpubg='[0;48;5;${clr[hos]};38;5;${clr[l]}m'
promptparts[timefmt]="[0;48;5;${clr[tim]};38;5;${clr[d]}m Command: [1m%J [0;38;5;${clr[tim]}m${set[end]}
[0;48;5;${clr[cwd]};38;5;${clr[l]}m Elapsed time: [1m%*E [0;38;5;${clr[cwd]}m${set[end]}
$timefmt_ucpubg user CPU time: [1m%U$timefmt_ucpubg \
kernel CPU time: [1m%S$timefmt_ucpubg \
(total: [1m%P$timefmt_ucpubg)[0;38;5;${clr[hos]}m${set[end]}"

promptparts[sudo]="[0;1;48;5;${clr[err]};38;5;${clr[l]}m ${icn[sud]} SUDO [0;38;5;${clr[err]};48;5;${clr[sud]}m${set[end]}\
[1;38;5;${clr[d]}m Please enter your password [0;38;5;${clr[sud]}m${icn[sud_end]}[0m "

# default __vlkprompt_internal values
declare -A vlkprompt_internals=(
    [pwd]=
    [pwd_contents]="${contents[cwd]}"
    [pwd_writable]=
    [old_time]=
    [timer_str]=
    [timer_str_small]=
    [right_prompt]=
    [tmpdir]='${TMPPREFIX:-${XDG_RUNTIME_DIR:-/tmp}}/vlkprompt-internal.zsh'
)

precmds[pwd]="__vlkprompt::precmd::dirtype() {
    if [[ \${PWD-} == \${__vlkprompt_internal[pwd]} ]]; then
        # If current directory is the same as it was last time this was run, don't change anything.
        psvar[${idx[wri]}]="\${__vlkprompt_internal[pwd_writable]}"
    else
        # need to re-run git/writable commands
        local git_info=\"\${\${(M)\$(git config --get remote.origin.url 2>/dev/null|| :)%/*/*}#/}\"
        [[ -w \${PWD-} ]] && psvar[${idx[wri]}]=1
        # if it is a git repo, set contents to git
        if [[ -n \${git_info-} ]]; then
            __vlkprompt_internal[pwd_contents]=\"${contents[git]}\"
            __vlkprompt_internal[right_prompt]=\"\${git_info}\"
        elif [[ -h \${PWD-} ]]; then
            __vlkprompt_internal[pwd_contents]=\"${contents[lnk]}\"
        else
            __vlkprompt_internal[pwd_contents]=\"${contents[cwd]}\"
        fi
        __vlkprompt_internal[pwd]=\"\$PWD\"
        __vlkprompt_internal[pwd_writable]=\"\${psvar[${idx[wri]}]}\"
    fi
}"

precmds[vev]="__vlkprompt::precmd::venv() {
    if [[ -n \${VIRTUAL_ENV-} ]]; then
        psvar[${idx[vev]}]=1
        __vlkprompt_internal[venv_str]="\${VIRTUAL_ENV##*/}"
    fi
}
# needed for proper python venv string
export VIRTUAL_ENV_DISABLE_PROMPT=1
precmd_functions+=('__vlkprompt::precmd::venv')"

precmds[con]="__vlkprompt::precmd::conda() {
    if [[ -n \${CONDA_DEFAULT_ENV-} ]]; then
        psvar[${idx[con]}]=1
        __vlkprompt_internal[conda_str]="\${CONDA_DEFAULT_ENV}"
    fi
}
precmd_functions+=('__vlkprompt::precmd::conda')"

precmds[sud]="# if in distrobox, sudo access is always granted
if [[ -z \${DISTROBOX_ENTER_PATH-} ]]; then
    __vlkprompt::precmd::sudo() {
        if sudo -vn &>/dev/null; then
            psvar[${idx[sud]}]=1
        else
            psvar[${idx[sud]}]=''
        fi
    }
    precmd_functions+=('__vlkprompt::precmd::sudo')
fi"

precmds[tim]="__vlkprompt::precmd::timer() {
    local -i timer=\$((SECONDS - \${__vlkprompt_internal[old_time]}))
    # Don't show timer if it is under 14 seconds
    ((timer < 14)) && return 0
    local leading_zero timedisp timedisp_sm
    if ((timer > 60)); then
        local -i hour=\$((timer / 3600))
        local -i min=\$(((timer % 3600) / 60))
        local -i sec=\$((timer % 60))
        if ((hour > 0)) {
            timedisp=\"\${timedisp}\${hour}h \"
            timedisp_sm=\"\${timedisp_sm}\${hour}:\"
            ((min < 10)) && leading_zero=0
        }
        if ((min > 0)) {
            timedisp=\"\${timedisp}\${min}m \"
            timedisp_sm=\"\${timedisp_sm}\${leading_zero:-}\${min}:\"
            ((sec < 10)) && leading_zero=0
        }
        if ((sec > 0)){
            timedisp=\"\${timedisp}\${sec}s \"
            timedisp_sm=\"\${timedisp_sm}\${leading_zero:-}\${sec}:\"
        }
        timedisp=\"\${timedisp%* }\"
        timedisp_sm=\"\${timedisp_sm%*:}\"
    else
        timedisp=\"\${timer}s\"
        timedisp_sm=\"\${timer}\"
    fi
    psvar[${idx[tim]}]=1
    __vlkprompt_internal[timer_str]=\"\$timedisp\"
    __vlkprompt_internal[timer_str_small]=\"\$timedisp_sm\"
}
precmd_functions+=('__vlkprompt::precmd::timer')"

promptwidgets[vim]="__vlkprompt::widget::keymap() {
    if [[ \${KEYMAP-} == vicmd ]]; then
        psvar[${idx[vim]}]=1
    else
        psvar[${idx[vim]}]=
    fi
    zle reset-prompt
}
zle -N zle-keymap-select __vlkprompt::widget::keymap"

promptwidgets[shortprompt]="__vlkprompt::widget::shortprompt() {
    [[ \${CONTEXT-} == start ]] || return 0
    ((\${+zle_bracketed_paste})) && print -r -n - \"\${zle_bracketed_paste[1]}\"
    zle recursive-edit
    local -i ret=\$?
    ((\${+zle_bracketed_paste})) && print -r -n - \"\${zle_bracketed_paste[2]}\"
    if [[ \$ret == 0 && \${KEYS-} == \$'\4' ]]; then
        psvar[${idx[short]}]=1
        zle reset-prompt
        exit
    fi
    psvar[${idx[short]}]=1
    RPROMPT=
    zle reset-prompt
    psvar=()
    __vlkprompt_internal+=(
        [old_time]=\$SECONDS
        [timer_str]=
        [timer_str_small]=
    )
    RPROMPT="\${__vlkprompt_internal[right_prompt]}"
    if ((ret)); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}
zle -N zle-line-init __vlkprompt::widget::shortprompt"

promptparts[login]="[[ \$- == *l* ]] && __vlkprompt_internal[login_content]=\"${contents[log]}\""

promptparts[host]="if [[ -n \${CONTAINER_ID-} ]]; then
    __vlkprompt_internal[host_content]=\"${contents[dbx]}\"
elif [[ \${HOSTNAME-} != \${CURRENT_HOSTNAME-} ]]; then
    __vlkprompt_internal[host_content]=\"${contents[hos]}\"
fi"

# check if you're able to use this. requires zsh-defer for deferred commands
promptparts[ability]="[[ "\$-" == *i* && -z \$BASH_VERSION && \$TERM != linux && -z \${VLKPROMPT_SKIP:-} ]] || {
    return 1
    exit 1
}
type zsh-defer &>/dev/null || return"

if ! command -v conda &>/dev/null; then
    echo "command 'conda' not found. Removing from prompt"
    contents[con]=''
    precmds[con]=''
else
    vlkprompt_internals[conda_str]=
fi
if ! command -v pip &>/dev/null; then
    echo "command 'pip' not found. Removing from prompt"
    contents[vev]=''
    precmds[vev]=''
else
    vlkprompt_internals[venv_str]=
fi

# echo "
# PROMPT=\"${set[sgr]}%(${idx[short]}V.."$'\n'")\${(j..)EXTRA}\
# ${contents[con]:-}${contents[vev]:-}\"\
# "

promptparts[prompt]="PROMPT='${set[sgr]}%(${idx[short]}V..
)\${__vlkprompt_internal[login_content]-}\${__vlkprompt_internal[host_content]-}\
${contents[con]-}${contents[vev]-}\
${contents[tim]}${contents[job]}${contents[err]}\
${contents[pwd]}${contents[sud]}'"

promptparts[rprompt]=

printf '\e[0m[%s] => %s\e[0m\n' "${(@kv)promptparts}" "${(@kv)contents}" # "${(@kv)promptwidgets}" "${(@kv)precmds}"
# printf "\e[0m[%s] => %s${set[end]}\e[0m\n" "${(@kv)contents}"
