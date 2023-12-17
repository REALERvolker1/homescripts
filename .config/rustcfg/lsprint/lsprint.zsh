#!/usr/bin/zsh
emulate -L zsh
set -euo pipefail

# my personal config, not for redistribution
### It is paramount that you use a ls command that allows the --width flag, always set it to 1
__lsprint::ls() {
    \eza -AG --width 1 --group-directories-first --icons=always --color=always /bin
}

typeset -A lsprint_config=(
    [min_height]=40
    [min_width]=50
)
typeset -ag __lsprint_cache=()

# get user-defined command first
((${+functions[__lsprint::ls]})) || {
    if ((${+commands[ls]})); then
        __lsprint::ls() {
            \ls -AG --width=1 --group-directories-first --color=always
        }
    else
        # fallback for if you don't have ls for some reason
        __lsprint::ls() {
            \print -l ${PWD:-.}/(.|)*(N:t)
        }
    fi
}

__lsprint::refresh() {
    local -a lsprint
    lsprint=("${(@f)$(__lsprint::ls)}")
    local -a lsprint_no_ansi

    # remove all ansi escapes from lsprint
    # then store the length (N) of match (##*)
    lsprint_no_ansi=(${(N)"${(*@f)lsprint//$'\e'\[[^[:alpha:]]#[[:alpha:]]}"##*})

    # string = length
    # local -A tmp
    # tmp=(${lsprint:^lsprint_no_ansi})

    local -a tmp_arr=()
    local tmpstr=''
    local -i count=1
    local -i line_width=0
    local -i max_div_2=0
    local -i line_max_width=0
    local -i next_line_width=0
    local -i max_width=$((COLUMNS - 4))
    local i len key
    local space=' '

    for ((i = 1; i <= ${#lsprint_no_ansi}; i++)); do
        len=$lsprint_no_ansi[$i]
        key=$lsprint[$i]

        ((len > max_width)) && continue
        next_line_width=$((line_width + len))
        ((line_max_width < len)) && line_max_width=$len

        # the max width can change after the stuff was pushed to the array.
        if ((next_line_width > max_width)); then
        # if ((${#tmp_arr[@]} > (max_width / line_max_width))); then
            tmpstr="${(j..)tmp_arr}"
            # print -v tmpstr -C ${#tmp_arr[@]} $tmp_arr
            __lsprint_cache+=($tmpstr)
            line_max_width=0
            line_width=0
            tmp_arr=()
        fi

        line_width+=$len
        tmp_arr+=("${key}${(r:$((line_max_width - len)):: :)space}") # ${(r:$((line_max_width - len)):: :)space}
    done
    # printf '[%s] = %s\n' "${(@kv)tmp[@]}"
    # printf '= %s\n' "${lsprint_no_ansi[@]}"
}


__lsprint::print() {
    ((LINES > ${lsprint_config[min_height]})) || return
    printf '│ %s │\n' $__lsprint_cache
}




__lsprint::refresh



__lsprint::print
