#!/usr/bin/dash
set -eu

list() {
    #loginctl list-sessions --no-pager --no-legend | grep -oP "$(id -u)\s+${USER}.*tty\K[0-9]+"
    loginctl list-sessions --no-pager --no-legend | grep -oP ".*tty\K[0-9]+$"
}
bar() {
    ttys="$(list)"
    echo "$ttys"
}
case "${1:-}" in
    *show)
        bar
        ;;
    *poll)
        while true; do
            bar
            sleep 5
        done
        ;;
    *switch)
        dmenucmd="rofi -dmenu"
        [ -z "${DISPLAY:-}" ] && dmenucmd="fzf"
        sel="$(printf 'Switch to TTY %s\n' $(list | grep -v "$XDG_VTNR") | $dmenucmd)"
        selected="$(echo "$sel" | grep -oP '[0-9]+$')"
        chvt $selected
        ;;
    *)
        echo "${0##*/}" '--show | --poll | --switch'
        exit 1
        ;;
esac

