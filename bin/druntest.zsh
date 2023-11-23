#!/usr/bin/zsh

typeset -A desktops=()
typeset -a desktopfiles=()

foreach i (${~${(s.:.)XDG_DATA_DIRS}//%/\/applications/*.desktop(N)}) {
    local myicon=''
    local myexec=''
    local myname=''
    local line
    local l_val
    while read -r line; do
        l_val="${line#*=}"
        case $line in
            Icon=*) [[ -z ${myicon:-} ]] && myicon="$line" ;;
            Name=*) [[ -z ${myname:-} ]] && myname="$line" ;;
            Exec=*) [[ -z ${myexec:-} ]] && myexec="$line" ;;
        esac
    done < <(grep -E '^(Name|Icon|Exec)=' "$i")
    desktops+=(["$i"]="${myicon:-}"$'\t'"${myname:-}"$'\t'"${myexec:-}")
    #desktopfiles+=("$i")
    #typeset -a
}

printf '[%s]=%s\n' ${(@kv)desktops}
