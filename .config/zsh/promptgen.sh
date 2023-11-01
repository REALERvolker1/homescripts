#!/usr/bin/bash
# shellcheck disable=2016
# set -euo pipefail
# IFS=$'\n\t'

# for command not found handler
# pacman -Fl | grep -P "[^\s]+\s+(/|)(usr|)/(local/|)bin/${query}$"
# grep -P "[^\s]+\s+(/|)(usr|)/(local/|)bin/${query}$" "$XDG_RUNTIME_DIR/vlkprompt-command-not-found.cache"

declare -A colors=(
    [text_l]=255
    [text_d]=233
    [sudo]=196
    [cwd]=33
    [cwd_lnk]=45
    [git]=141
    [vim]=120
    [err]=52
    [job]=172
    [time]=226
    [login]=57
    [ps2]=93
)
declare -A tcolor=(
    [sudo]="${colors[text_d]}"
    [cwd]="${colors[text_l]}"
    [cwd_lnk]="${colors[text_d]}"
    [git]="${colors[text_d]}"
    [vim]="${colors[text_d]}"
    [err]="${colors[text_l]}"
    [job]="${colors[text_d]}"
    [time]="${colors[text_d]}"
    [login]="${colors[text_l]}"
    [ps2]="${colors[text_l]}"
)

declare -A icons=(
    [cwd_ro]=
    [cwd_rw]=
    [git]=󰊢
    [err]=󰅗
    [job]=󱜯
    [time]=󱑃
    [login]=󱌒
    [end]=
    [end_r]=
    [end_sudo]=' '
)

declare -A set=(
    [sgr_full]='%k%f%b%u%s'
    [sgr]='%k%f%b'
)

declare -A index=(
    [short]=130
    [timer]=134
    [sudo]=135
    [writable]=136
    [symlink]=137
    [git]=138
    [vim]=139
)

endfggen() {
    local outputstr
    if [[ ${4:-} == '--no-fg_ends' ]]; then
        outputstr="%F{${colors[$2]}}.$3"
    else
        outputstr="%(${1}.%F{${colors[$2]}}.${fg_ends[$3]})"
    fi
    echo "$outputstr"
}
contentgen() {
    echo "%(${index[short]}V.. ${icons[$1]}) ${2:+$2 }"
}

declare -A contents=(
    [login]="$(contentgen login)"
    [time]="$(contentgen time "\${__vlkprompt_internal[time_str]}")"
    [job]="$(contentgen job "%j")"
    [err]="$(contentgen err "%?")"
    [cwd]=" %(${index[short]}V.%\$((COLUMNS / 4))<..<%~.\${__vlkprompt_internal[dir_icon]} %\$((COLUMNS / 2))<..<%~) "
)

for i in "${!contents[@]}"; do
    contents[$i]="%K{${colors[$i]}}${icons[end]}%B%F{${tcolor[$i]}}${contents[$i]}${set[sgr]}%F{${colors[$i]}}"
    # echo "${contents[$i]}"
done
contents[sudo]="%K{${colors[sudo]}}%(${index[short]}V..${icons[end]})%F{${colors[sudo]}}%(${index[short]}V.%k${icons[end]}. %k${icons[end_sudo]})"

contents[job]="%(1j.${contents[job]}.)"
contents[err]="%(0?..${contents[err]})"
contents[sudo]="%(${index[sudo]}V.${contents[sudo]}.${icons[end]})"

FULLPROMPT="${set[sgr_full]}
${contents[login]}\
${contents[time]}\
${contents[job]}\
${contents[err]}\
${contents[cwd]}\
${contents[sudo]}\
${set[sgr_full]} "

cat <<BRUH

declare -A __vlkprompt_internal=(
    [time_str]='00:00'
    [dir_icon]="${icons[cwd_rw]}"
)

PROMPT='${contents[time]}${contents[job]}${contents[err]}${contents[cwd]}${contents[sudo]}${set[sgr_full]} '

[[ \$- == *l* ]] && PROMPT='${contents[login]}'"\$PROMPT"
PROMPT='${set[sgr_full]}%(${index[short]}V..
)%F{0}'"\$PROMPT"

PROMPT2='${set[sgr_full]}%K{${colors[ps2]}}%B%F{${tcolor[ps2]}} %_ ${set[sgr]}%F{${colors[ps2]}}${contents[sudo]}${set[sgr_full]} '

__vlkprompt-zle-line-init() {
    [[ \$CONTEXT == start ]] || return 0
    ((\${+zle_bracketed_paste})) && print -r -n - "\${zle_bracketed_paste[1]}"
    zle recursive-edit
    local -i ret=\$?
    ((\${+zle_bracketed_paste})) && print -r -n - "\${zle_bracketed_paste[2]}"
    if [[ \$ret == 0 && \$KEYS == \$'\4' ]]; then
        psvar[${index[short]}]=1
        zle reset-prompt
        exit
    fi
    local has_sudo="\${psvar[${index[sudo]}]}"
    psvar[${index[short]}]=1
    RPROMPT=
    zle reset-prompt
    psvar=()
    psvar[${index[sudo]}]="\$has_sudo"
    __vlkprompt_internal[old_time]=\$SECONDS
    __vlkprompt_internal[timer_str]=
    RPROMPT="\${__vlkprompt_internal[right_prompt]}"
    if ((ret)); then
        zle send-break
    else
        zle accept-line
    fi
    return ret
}
zle -N zle-line-init __vlkprompt-zle-line-init
return
BRUH
