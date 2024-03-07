#!/usr/bin/env bash
set -euo pipefail
[[ -t 0 ]] && OLDSTTY="$(stty --save)"

if [[ -t 2 ]]; then
    _log_head='[0;1m[[2mLOG[0;1m][0m'
    _log_head_warn='[0;1m[[93mWARN[0;1m][0m'
    _log_head_err='[0;1m[[91mERROR[0;1m][0m'
    # replaces the ` character with the date
    _log_date='[0;1m[[96m`[0;1m][0m'
else
    _log_head='[LOG]'
    _log_head_err='[ERROR]'
    _log_head_warn='[WARN]'
    _log_date='[`]'
fi

_log() {
    local loghead="$_log_head"
    local -i shiftint=1
    case "${1-}" in
    --err)
        loghead="$_log_head_err"
        ;;
    --warn)
        loghead="$_log_head_warn"
        ;;
    *)
        shiftint=0
        ;;
    esac
    ((shiftint)) && shift 1

    loghead="${loghead-}${loghead:+ }${_log_date//\`/$(date +'%F_%T')}${_log_date:+ }"

    printf "${loghead-}%s\n" "$@" >&2
}

_panic() {
    local IFS=' '
    _log --err "$*"
    exit 1
}

clear() {
    echo -en '[0m[H[2J(B)0\017[?5l7[0;0r8' >&2
}

declare -a infodisp=()

if [[ -t 0 && -t 2 ]]; then
    # clear screen
    clear
    if [[ -t 1 ]]; then
        infodisp+=("You are currently in a terminal.")
    fi
else
    _panic "Error, must be running in a terminal!"
fi

reset() {
    clear
    if ! stty "${OLDSTTY-}"; then
        _log --err "Invalid stty! Setting stty to sane"
        stty sane
    fi
    echo -en '\e[?25h' >&2
}

quit() {
    reset
    _log "Quitting..." >&2
    exit 1
}
# reset STTY when the script exits, just in case
trap 'reset' EXIT
stty sane

header='Choose one of the following'
declare -a choices=()

# argparse
for i in "$@"; do
    case "$i" in
    --header=*)
        header="${i#*=}"
        ;;
    *)
        choices+=("${i:----}")
        ;;
    esac
done

if ((${#choices[@]})); then
    if ((${#choices[@]} == 1)); then
        echo "${choices[0]}"
        exit 0
    fi
else
    choices+=(yes no)
fi

# getpos() {
#     IFS='[;' read -p $'\e[6n' -d R -rs _ Y X _
# }
# setpos() {
#     echo -en "\e[${1:-$Y};${2:-$X}H" >&2
# }
change_select() {
    local -i current_selected=$SELECTED
    case "${1-}" in
    --up)
        if ((current_selected <= 1)); then
            SELECTED=0
        else
            ((SELECTED -= 1))
        fi
        ;;
    --down)
        if ((current_selected >= (SELECT_MAX - 1))); then
            SELECTED=$SELECT_MAX
        else
            ((SELECTED += 1))
        fi
        ;;
    esac
    render
}
render() {
    [[ ${1-} != '--no-reset' ]] && clear

    printf '\e[?25l\n\e[0;1m%s\e[0m\n\n' "$header" >&2

    local i iprefix
    local -i count=0
    for i in "${choices[@]}"; do
        if ((count == SELECTED)); then
            iprefix="\e[1;92m> \e[0;1m"
        else
            iprefix='  '
        fi
        printf "\e[0m${iprefix}%s\e[0m\n" "$i" >&2
        ((count += 1))
    done

    if ((${#infodisp[@]})); then
        printf '%b\n' '' "\e[0;1mINFO:\e[0m"
        printf '\e[0;33m%s\e[0m\n' "${infodisp[@]}"
    fi
}
trap 'render' SIGWINCH

# get window size
shopt -s checkwinsize
eval '(:;:)'

declare -i SELECTED=0
declare -i SELECT_MAX=$((${#choices[@]} - 1))

# initial position
# getpos
# X_INIT=$X
# Y_INIT=$Y
# initial render
render --no-reset

# useful resources
# https://unix.stackexchange.com/questions/294908/read-special-keys-in-bash
while true; do
    unset key
    read -rsn1 key
    # read user input
    case "${key-}" in
    '')
        selected_item=${choices[$SELECTED]}
        ;;
    q)
        quit
        ;;
        # [[:graph:]])
        #     echo "$key"
        #     ;;
        # $'\x09') # TAB
        #     echo tab pressed
        #     ;;
        # $'\x7f')
        #     echo backspace
        #     ;;
        # $'\x01')
        #     echo Allselect
        #     ;;
    $'\x1b')
        read -rsn1 tmp
        case "${tmp-}" in
        '')
            # ESCAPE key
            quit
            # echo ESC
            ;;
        '[')
            read -rsn1 tmp
            [[ "${tmp-}" == 'O' ]] && read -rsn1 tmp
            case "${tmp-}" in
            A)
                change_select --up
                ;;
            B)
                change_select --down
                ;;
            esac
            ;;
        k)
            change_select --up
            ;;
        j)
            change_select --down
            ;;
        *)
            continue
            ;;
        esac
        ;;

    esac
    [[ -n ${selected_item-} ]] && break
done
echo "$selected_item"
# choice --header="Hello World!" 'unn, sure' no bruh
