#!/usr/bin/dash
# This is meant to be a temporary fix until I fix pointer-rs/hyprpointer
set -eu

TOUCHPAD_STATUSFILE="${XDG_RUNTIME_DIR:-/tmp}/hyprpointer-tmp-statusfile"
TOUCHPAD_VAR='$TOUCHPAD_ENABLED'

_notify() {
    header="$1"
    shift 1
    notify-send -a "${0##*/}" "$header" "$*" &
    echo "$header" "$*"
}

_panic() {
    _notify Error "$@"
    exit 1
}

# This requires you to set the variable in the hyprland config
set_status() {
    hyprctl keyword "$TOUCHPAD_VAR" "$1" -r
    echo "$1" >"$TOUCHPAD_STATUSFILE"
    _notify set_status "Set touchpad status to $1"
}

normalize() {
    # only works with glorious mice. We don't need to be fancy tho
    if hyprctl devices | grep -q glorious; then
        set_status false
    else
        set_status true
    fi
}

get_stat_recursion=0
# side effect: mutates get_stat_recursion, sets current_status
get_status() {
    if [ "$get_stat_recursion" -gt 2 ]; then
        _panic "get_status recursion reached limit: $get_stat_recursion"
    else
        get_stat_recursion=$((get_stat_recursion + 1))
    fi
    if [ -f "$TOUCHPAD_STATUSFILE" ]; then
        current_status="$(cat "$TOUCHPAD_STATUSFILE")"
    elif [ -e "$TOUCHPAD_STATUSFILE" ]; then
        _panic "TOUCHPAD_STATUSFILE '$TOUCHPAD_STATUSFILE' exists and is not a file!"
    else
        normalize
        get_status
    fi
}

case "${1:-}" in
normalize)
    normalize
    ;;
toggle)
    get_status
    case "$current_status" in
    true) current_status=false ;;
    false) current_status=true ;;
    *) _panic "Invalid current_status: '$current_status'" ;;
    esac

    set_status "$current_status"
    ;;
set)
    set_status "$2"
    ;;
*)
    echo "Invalid arg: '${1:-}'

Available actions:

normalize           Turn touchpad on if mice are found, otherwise disable it
toggle              Toggle touchpad state
set <true | false>  Set the touchpad state

This sets the variable '$TOUCHPAD_VAR'.
Please set the per-device property 'enabled = $TOUCHPAD_VAR' in your hyprland config,
and set the default value of that variable to true to use this program."
    ;;

esac
