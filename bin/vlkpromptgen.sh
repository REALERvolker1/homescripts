#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

# icon config
declare -A end_icon icon_fancy icon_ascii

icon_fancy[dir_ro]=
icon_fancy[dir_rw]=
icon_fancy[git]=󰊢
icon_fancy[vim]=
icon_fancy[err]=󰅗
icon_fancy[job]=󱜯
icon_fancy[end_sudo]=' '

icon_ascii[dir_ro]='-'
icon_ascii[dir_rw]='.'
icon_ascii[git]='G'
icon_ascii[vim]='V'
icon_ascii[err]='X'
icon_ascii[job]='J'
icon_ascii[end_sudo]=']#'

end_icon[dashline]=
end_icon[powerline]=
end_icon[fallback]=']'

# color config
declare -A hicolor locolor text

# hicolor[ligh_text]=255
# hicolor[dark_text]=232
hicolor[dir]=33
hicolor[git]=141
hicolor[vim]=120
hicolor[err]=52
hicolor[job]=172
hicolor[sud]=196
hicolor[ps2]=93
hicolor[ps3]=95

# locolor[ligh_text]=7
# locolor[dark_text]=0
locolor[dir]=4
locolor[git]=5
locolor[vim]=2
locolor[err]=1
locolor[job]=3
locolor[sud]=6
locolor[ps2]=5
locolor[ps3]=5

text[hi_ligh]=255
text[hi_dark]=232
text[lo_ligh]=7
text[lo_dark]=0

# psvar config -- indices of psvar designated for each property
declare -A psvar
psvar[transient]=130
psvar[vim]=131
psvar[git]=132
psvar[dir]=133

# end config
# expand variables

TAB=$'\t'
LINE=$'\n'

_array_validate() {
    [ -z "${*:-}" ] && return 1
    local i err
    local -a errors
    for i in "$@"; do
        if [[ "$(declare -p "$i" 2>/dev/null)" != 'declare -A'* ]]; then
            err=true
            errors+=("$i")
        fi
    done
    if [ -n "${err:-}" ]; then
        for i in "${errors[@]}"; do
            echo "Error, '$i' is not a strongly typed associative array! Initialize it with 'declare -A $i'" >&2
        done
        return 1
    else
        return 0
    fi
}

_print_assoc() { # assoc array, str
    local arr="${1:?Error, please provide an array to print}"
    _array_validate "$arr"
    local div_key="${2:-$TAB}"
    local i
    for i in $(eval "printf '%s\n' \${!${arr}[@]}"); do
        printf "%s${div_key}%s\n" "$i" "$(eval "echo \"\${${arr}[$i]}\"")"
    done
}

_array_sandwich() { #array_name, output_array, text_pattern
    # pattern is text surrounding element like "element\`here"
    local arr="${1:?Error, please provide an array to iterate through}"
    local output_array="${2:?Error, please provide an array to assign new values to}"
    _array_validate "$arr" "$output_array"
    local pattern="${3:-\`}"
    local i key val
    for i in $(_print_assoc "$arr" =); do
        key="${i%%=*}"
        val="${i#*=}"
        eval "${output_array}[${key}]='${pattern//\`/$val}'"
    done
}

declare -A hicolor_fg hicolor_bg locolor_fg locolor_bg

_array_sandwich hicolor hicolor_fg '%{\e[38;5;`m%}'
_array_sandwich hicolor hicolor_bg '%{\e[48;5;`m%}'

_array_sandwich locolor locolor_fg '%{\e[3`m%}'
_array_sandwich locolor locolor_bg '%{\e[4`m%}'

_print_assoc locolor_fg

# for i in "${!hicolor_fg[@]}"; do
#     printf '%s\t%s\n' "$i" "${hicolor_fg[$i]}"
# done
# declare -p psvar
