#!/usr/bin/zsh
# script by vlk to run a clipboard persistence command
set -euo pipefail
IFS=$'\n\t'

CLIPHISTPATH="$XDG_RUNTIME_DIR/${${0##*/}%.*}-$$-$XDG_SESSION_ID.hsts"

_panic() {
    if [[ ${1:-} == '--nice' ]]; then
        shift 1
        local -i retval=0
    fi
    printf '%s\n' "$@"
    exit "${retval:-1}"
}

_panic --nice "Unfinished script. Will not execute further"

typeset -a checkdeps=(ps rm grep pkill)

for i in "$@"; do
    i_val="${i:+${i#*=}}"
    case "${i:-}" in
        '--dmenucmd='*)
            DMENU_COMMAND="$i_val"
            ;;
        '--platform='*)
            PLATFORM="$i_val"
            ;;
        -*)
            # The following is a deliberate syntax error
            _panic "${0##*/} --key=val --key2=val2" \
                "--platform=platform_name   (either wayland or xorg)" \
                "--dmenucmd='dmenu_command --arg1 --arg2'  (full command for your dmenu-like wrapper)"
        ;;
    esac
done

checkdeps+=("${${DMENU_COMMAND:=rofi -dmenu}%% *}")

case "${PLATFORM:=${${WAYLAND_DISPLAY:+wayland}:-${DISPLAY:+xorg}}}" in
    wayland)
        checkdeps+=(wl-paste clipman)
        ;;
    xorg)
        checkdeps+=(xclip xsel)
        ;;
    *)
        _panic "Invalid platform '$PLATFORM'! Supported platforms: 'xorg' or 'wayland'"
    ;;
esac

# check dependencies
set -A faildeps
for i in "${(@)checkdeps}"; do
    command -v $i &>/dev/null || faildeps+=("$i")
done
((${#faildeps})) && _panic "Missing dependencies: ${(pj:, :)faildeps}"

# print config

printf '%s\n' \
    "PLATFORM='$PLATFORM'" \
    "DMENU_COMMAND='$DMENU_COMMAND'"

# kill_paste_cmds() {
#     local clips
#     # clips="$(ps -eo pid,comm,args | grep -oP "\s*\K[0-9]+(?=.*([^(grep)])${1:?Error, pass the name of the program to grep!})")"
#     clips="$(pgrep "${1:?Error, pass the name of the program to grep!}")"
#     local -i retval=$?
#     (($retval)) && return
#     local i
#     while read -r i; do
#         echo "$i"
#     done <<< "$clips"
# }

:>"$CLIPHISTPATH" || [[ ! -w $CLIPHISTPATH ]] || _panic "Error, could not create file $CLIPHISTPATH"

TRAPEXIT() {
    rm -f "$CLIPHISTPATH"
}

case "$PLATFORM" in
    wayland)
        pkill -ef 'wl-paste' || :
        wl-paste -t text --watch clipman store --histpath="$CLIPHISTPATH"
    ;;
    xorg)
        _panic "Error, xorg is not implemented yet!"
    ;;
esac

# ps -ao comm,args | grep -P '([^(grep)])wl-paste.*--watch'
