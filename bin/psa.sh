#!/usr/bin/bash
set -euo pipefail
# IFS=$'\n\t'
IFS=$' \n\t'

# I am using a different psa right now -- psa-rs. This is still here because on some systems I might need it.

for i in pidstat fzf realpath dircolors pstree; do
    if ! command -v "$i" &>/dev/null; then
        echo "Missing dependency command '$i'" >&2
        exit 1
    fi
done
[ -z "${LS_COLORS:-}" ] && eval "$(dircolors -b <(dircolors -p))"

if ! command -v lscolors &>/dev/null; then
    lscolors() {
        if [[ -e ${1:-} ]]; then
            ls -A1d --color=always "${1:-}"
        else
            echo "${1:-}"
        fi
    }
fi

exe_color="[$(echo "$LS_COLORS" | tr -s ':' '\n' | grep -m 1 -oP 'ex=\K[^:]*')m"

arg_colorizer() {
    local i i_key i_val join firstarg
    local -a output=()
    for i in "$@"; do
        if [ -z "${firstarg:-}" ]; then
            if [ ! -e "$i" ] && command -v "$i" &>/dev/null && [[ "$i" != *'/'* ]]; then
                i="${exe_color:-[1m}$i"
                firstarg='y'
                # i="[1m${i}[0m"
            fi
        fi
        if [[ "$i" == *'='* ]]; then
            i_key="${i%%=*}"
            i_val="${i#*=}"
            join='='
        else
            i_key="$i"
            i_val=''
            join=''
        fi
        if [ -e "$i_key" ]; then
            i_key="$(lscolors "$i_key")"
        elif [ -e "$i_val" ]; then
            i_val="$(lscolors "$i_val")"
        fi
        output+=("${i_key}${join}${i_val}")
        # echo -n "[0m${output}[0m "
    done
    printf '[0m%s[0m ' "${output[@]}"
}

PIDSTAT='pidstat --human -lRtU -p'
export S_COLORS=always
declare -A actions=(
    [stat]='1: Get statistics'
    [tree]='2: Print process tree'
    [kill]='3: Kill process'
)

ps="$(
    ps -eo pid,comm,args |
        tr -s '[:blank:]' ' ' |
        sed -E 's/^\s+([0-9]+) ([^ ]+)(\s+([^ ]+))?/[0m[1;33m\1[0m [1;94m\2[0m[32m\3/g' |
        fzf --ansi --preview-window='down,25%' --header-lines=1 --preview="$PIDSTAT \$"'(echo {} | grep -oP "^\\s*\\K[^ ]*")' -q "${1:-}"
)"
[ -z "${ps:-}" ] && exit 1

pid="${ps%% *}"
tmpps="${ps#* }"
comm="${tmpps%% *}"
tmpps="${tmpps#* }"
args="${tmpps# *}"

commstr="[1mPID:[0m $pid
[1mName:[0m $comm
[0m$(arg_colorizer $args)[0m"

case "$(printf '%s\n' "${actions[@]}" | sort | fzf --ansi --preview-window='down,25%' --preview="echo '$commstr'")" in
"${actions[stat]}")
    exec sh -c "$PIDSTAT $pid"
    ;;
"${actions[tree]}")
    pstree -sp "$pid"
    # parent=''
    # declare -a children
    # found=''
    # for i in $(ps -eo pid,comm --forest --no-headers); do
    #     if [[ "$i" == *"$pid"* ]]; then
    #         i="$(tput bold)$i$(tput sgr0)"
    #         found=1
    #     fi
    #     if [[ "$i" == *'\_'* ]]; then
    #         children+=("$i")
    #     else
    #         [ -n "$found" ] && break
    #         parent="$i"
    #         children=()
    #     fi
    # done
    # printf '%s\n' "$parent" "${children[@]}"
    ;;
"${actions[kill]}")
    echo "Are you sure you want to kill process ${pid}?"
    echo "$ps"
    echo -n '[y/N] > '
    read -r answer
    [ "$answer" != y ] && exit 0
    kill "$pid"
    ;;
*)
    echo "Error, please select a valid action!" >&2
    exit 1
    ;;
esac
