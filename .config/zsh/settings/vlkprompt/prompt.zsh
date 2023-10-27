#!/usr/bin/zsh
declare -A icn col idx set

idx[small]=130
idx[sud]=135
idx[cwd]=136
idx[git]=137
idx[vim]=138

if (($(tput colors) < 255)); then
    set[ansi]=''
    set[text_l]='%B%F{7}'
    set[text_d]='%B%F{0}'
    col[txl]=7
    col[txd]=0

    col[cwd]=4
    col[git]=5
    col[vim]=2
    col[err]=1
    col[job]=3
    col[hos]=4
    col[sud]=6
    col[ps2]=5
    col[ps3]=5
else
    set[ansi]='8;5;'
    set[text_l]='%B%F{255}'
    set[text_d]='%B%F{232}'

    col[txl]=255
    col[txd]=232
    col[cwd]=33
    col[git]=141
    col[vim]=120
    col[err]=52
    col[job]=172
    col[hos]=18
    col[sud]=196
    col[ps2]=93
    col[ps3]=89
fi

icn[cwd_ro]=
icn[cwd_rw]=
icn[git]=󰊢
icn[vim]=
icn[err]=󰅗
icn[job]=󱜯
icn[hos]=󰟀
icn[log]=󰌆
icn[sud]=' '

case "$ICON_TYPE" in
dashline)
    icn[end_l]=
    icn[end_r]=
    ;;
powerline)
    icn[end_l]=
    icn[end_r]=
    ;;
fallback)
    icn[cwd_ro]='-'
    icn[cwd_rw]='&'
    icn[git]='G'
    icn[vim]='V'
    icn[err]='X'
    icn[job]='J'
    icn[hos]='H'
    icn[log]='l'
    icn[sud]=']#'
    icn[end_l]=']'
    icn[end_r]='['
    ;;
esac
icn[cwd]="%(${idx[cwd]}V.${icn[cwd_rw]}.${icn[cwd_ro]})"

set[sgr]='%k%f%b%u%s'

# eval "$(printf "declare 'colorstx[%s]=${set[tx_esk]}%s${set[end_esc]}'\n" "${(@kv)colorstx}")"
# declare -A colf colb icns

declare -A vlkprompt prompt_tmp

promptify() {
    local icon_char color_i8 text_color_i8 content_str special_begin_str special_end_str
    if [ -n "${1:-}" ]; then
        icon_char="%(${idx[small]}V. . $1)"
    fi
    color_i8="$2"
    text_color_i8="$3"
    content_str="$4"
    special_begin_str="${5:-}"
    special_end_str="${6:-}"
    echo "${special_begin_str}%K{$color_i8}%B%F{$text_color_i8}$icon_char $content_str ${special_end_str}"
}
cwd_text='%$((COLUMNS / `))<..<%~'
# cwd_text="%(${idx[small]}V.${cwd_text//\`/4}.\` ${cwd_text//\`/2})"
# cwd_sm_text="${cwd_text//\`/4}"

prompt_tmp[cwd]="$(promptify '' "${col[cwd]}" "${col[txl]}" "${cwd_text//\`/${icn[cwd]}}")"
prompt_tmp[git]="$(promptify '' "${col[git]}" "${col[txd]}" "${cwd_text//\`/${icn[git]}}")"
prompt_tmp[vim]="$(promptify '' "${col[vim]}" "${col[txd]}" "${cwd_text//\`/${icn[vim]}}")"

# cwd="%(${idx[vim]}V.\`.%(${idx[git]}V.\`.\`))"
# for i in vim git cwd; do
#     i="%K{${col[$i]}}%B%F{${col[$i]}} %(${idx[small]}V..${icn[$i]} ) %\$((COLUMNS / 2))<..<%~ "
#     cwd="${cwd/\`/$i}"
# done

# vlkprompt[cwd]="$cwd"
# PS1="${set[sgr]}${vlkprompt[cwd]}${set[sgr]} "
# return
# printf "%%K{%s}\n" cwd git vim

# echo "${prompt_tmp[git]}"
# print -P "${prompt_tmp[git]}${set[sgr]}"
# prompt_tmp[cwdgit]="%(${idx[git]}V..)"
vlkprompt[git_tmp]="${prompt_tmp[git]}"
vlkprompt[cwd_tmp]="${prompt_tmp[cwd]}"
vlkprompt[cwdgit_tmp]="${vlkprompt[cwd_tmp]}"
# for some reason git does not work
vlkprompt[cwd]="%(${idx[vim]}V.${prompt_tmp[vim]}.%(${idx[git]}V.${vlkprompt[git_tmp]}.${vlkprompt[cwd_tmp]}))"
PS1="${set[sgr]}${vlkprompt[cwd]}${set[sgr]} "
# echo "$PS1"
__vlkprompt_precmd_dir () {
    psvar[${idx[vim]}]=''
    if git status &>/dev/null; then
        echo has git
        vlkprompt[cwdgit_tmp]="${vlkprompt[git_tmp]}"
        vlkprompt[cwd_color]="${col[git]}"
        psvar[${idx[git]}]=1
    else
        echo no git
        vlkprompt[cwdgit_tmp]="${vlkprompt[cwd_tmp]}"
        vlkprompt[cwd_color]="${col[cwd]}"
        psvar[${idx[git]}]=''
        if [ -w "$PWD" ]; then
            psvar[${idx[cwd]}]=1
        else
            psvar[${idx[cwd]}]=''
        fi
    fi
}
__vlkprompt_precmd_sudo() {
    if sudo -vn &>/dev/null; then
        psvar[${idx[sud]}]=1
    else
        psvar[${idx[git]}]=''
    fi
}
export -U precmd_functions=(__vlkprompt_precmd_dir __vlkprompt_precmd_sudo)

function zle-line-init zle-keymap-select {
    if [[ "$KEYMAP" == vicmd ]]; then
        psvar[${idx[vim]}]=1
    else
        psvar[${idx[vim]}]=''
    fi
    zle reset-prompt
}
zle -N zle-keymap-select

return
exit 0

eval "$(
    printf "declare 'icns[%s]=%%(${idx[small]}V. . %s )'\n" "${(@kv)icn}"
    printf "declare 'colf[%s]=%%F{%s}'\n" "${(@kv)col}"
    printf "declare 'colb[%s]=%%K{%s}'\n" "${(@kv)col}"
)"

# print -P "${colb[git]} ${icns[git]}${set[text_d]}Hello${set[sgr]}"

declare -A vlkprompt
vlkprompt[sudo_end]="${colb[dir]}%%%% ${set[sgr]}"

if [[ "${HOSTNAME:=$(cat /etc/hostname)}" != "${CURRENT_HOSTNAME:-///}" ]]; then
    vlkprompt[hos]="${colb[hos]}${colorstx[l]} $HOSTNAME "
else
    vlkprompt[hos]=''
fi
vlkprompt[err]="%(0?..${colb[err]}${colorstx[l]})"

export -U precmd_functions

__vlkprompt_precmd_dir () {
    if git status &>/dev/null; then
        colb[dir]="${colb[git]}"
        colf[dir]="${colf[git]}"
        icns[dir]="${icns[git]}"
    else
        colb[dir]="${colb[cwd]}"
        colf[dir]="${colf[cwd]}"
        icns[dir]="${icns[cwd]}"
        if [ -w "$PWD" ]; then
            psvar[${idx[cwd]}]=1
        else
            psvar[${idx[cwd]}]=''
        fi
    fi
}
if command -v sudo &>/dev/null && [ -z "${DISTROBOX_ENTER_PATH:-}" ]; then
    __vlkprompt_precmd_sudo () {
        if sudo -vn &>/dev/null; then
            # psvar[${idx[sud]}]=1
            vlkprompt[end]="${colf[dir]}${colb[sud]}${icn[end_l]} ${set[sgr]}${colf[sud]}${icn[sud]}"
        else
            # psvar[${idx[sud]}]=''
            vlkprompt[end]="${colf[dir]}${icn[end_l]}"
        fi
    }
    precmd_functions+=('__vlkprompt_precmd_sudo')
else
    vlkprompt[end]="\${colf[dir]}${icn[end_l]}"
fi

# PS1="${vlkprompt[hos]}${set[sgr]}\${colb[dir]}"
