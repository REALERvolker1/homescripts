#!/usr/bin/bash
# shellcheck shell=bash
# a script that does a thing.
set -euo pipefail
IFS=$'\n\t'

# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

_prompt() {
    local answer
    printf '%s\n' "$@"
    read -r -p "[y/N] > " answer
    if [[ ${answer:-} == y ]]; then
        return 0
    else
        return 1
    fi
}

_array_join() {
    local ifsstr=$'\n'
    if [[ "${1:-}" == '--ifs='* ]]; then
        ifsstr="${1#*=}"
        shift 1
    fi
    local oldifs="${IFS:-}"
    local IFS="$ifsstr"
    echo "$*"
    IFS="$oldifs"
}

_strip_color() {
    # Strip all occurences of ansi color strings from input strings
    # uncomment matches to do stuff with the strings themselves
    local ansi_regex='\[([0-9;]+)m'
    local i
    # local -a matches=()
    for i in "$@"; do
        while [[ $i =~ $ansi_regex ]]; do
            # matches+=("${BASH_REMATCH[1]}")
            i=${i//${BASH_REMATCH[0]}/}
        done
        echo "$i"
    done
}

# box-drawing characters, powerline characters, and some other nerd font icons, useful for output
#╭─┬─╮│    󰀄  󰕈
#├─┼─┤│   󰓎 󰘳  󰂽
#╰─┴─╯│   󰅟 󰘲 󰣇 󰣛
# 󰬛󰬏󰬌 󰬘󰬜󰬐󰬊󰬒 󰬉󰬙󰬖󰬞󰬕 󰬍󰬖󰬟 󰬑󰬜󰬔󰬗󰬌󰬋 󰬖󰬝󰬌󰬙 󰬛󰬏󰬌 󰬓󰬈󰬡󰬠 󰬋󰬖󰬎

# dependency check
declare -a faildeps=()
for i in ls lsd eza; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

# # argparse
# declare -A config=(
#     [bool]=0
#     [str]=''
# )
# declare -a files=()

# for i in "$@"; do
#     case "${i:=}" in
#     --bool)
#         config[bool]=1
#         ;;
#     --no-bool)
#         config[bool]=0
#         ;;
#     --str=)
#         config[str]="${i#*=}"
#         ;;
#     -*)
#         cat <<BRUH
# Error, invalid arg passed! '$i'

# Valid arguments include:
# --bool        enable bool
# --no-bool     disable bool
# --str='text'  Set str value

# [files]       All other args are passed as files

# BRUH
#         exit 2
#         ;;
#     *)
#         files+=("$i")
#         ;;
#     esac
# done

declare -a files=("$@")

declare -A testcodes=(
    [dir]=d
    [symlink]=h
    [socket]=S
    [pipe]=p
    [exec]=x
    [block_special]=b
    [char_special]=c
)

for file in "${files[@]}"; do
    # filepath="${i:-}"
    filetype=''
    for j in "${!testcodes[@]}"; do
        if test "-${testcodes[$j]}" "$file"; then
            filetype="$j"
            break
        fi
    done
    if [[ -z "${filetype:-}" ]]; then
        filetype=none
    fi
done
