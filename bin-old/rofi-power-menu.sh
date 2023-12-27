#!/usr/bin/env bash
# script by vlk
set -euo pipefail
IFS=$'\n\t'

if ! command -v systemctl &>/dev/null; then
    echo "Error, this requires systemd!"
    exit 2
fi

declare -A actions
actions[logout]="Log Out"
actions[reboot]="Restart"
actions[sleep]="Sleep"
actions[shutdown]="Shut Down"
actions[advanced]="Advanced options"

declare -A advanced_actions
advanced_actions[tty]="Switch active TTY"
advanced_actions[uefi]="UEFI reboot"
advanced_actions[hibernate]="Hibernate"
if [ -S "${YDOTOOL_SOCKET:-/tmp/.ydotool_socket}" ]; then
    advanced_actions_str="${advanced_actions[tty]}
${advanced_actions[uefi]}
${advanced_actions[hibernate]}"
else
    advanced_actions_str="${advanced_actions[uefi]}
${advanced_actions[hibernate]}"
fi

declare -a unruly_flatpaks=(
    'com.valvesoftware.Steam'
    'com.discordapp.Discord'
)
_kill_flatpaks() {
    if command -v flatpak &>/dev/null; then
        local grepstr
        grepstr="$(printf '%s|' "${unruly_flatpaks[@]}")"
        local unruly_procs
        unruly_procs="$(flatpak ps 2>/dev/null | grep -oE "(${grepstr::-1})" | uniq)"
        if [ -n "$unruly_procs" ]; then
            echo "Unruly flatpaks detected. Killing them"
            for i in $unruly_procs; do
                flatpak kill "$i" &
            done
            wait
        fi
    else
        echo "Flatpak is not installed. Skipping unruly flatpaks"
    fi
}

_tty_switch() {
    local selected_tty event_codes
    local ctrl alt f_code
    selected_tty="$(printf 'Switch to TTY %s\n' {1..10} | rofi -dmenu)"
    [ -z "${selected_tty:-}" ] && exit 1
    local tty_number="${selected_tty##* }"
    event_codes="$(cat '/usr/include/linux/input-event-codes.h')"
    _keycode() {
        echo "$event_codes" | grep -m 1 -oP "#define ${1}\t*\K.*"
    }

    ctrl="$(_keycode 'KEY_LEFTCTRL')"
    alt="$(_keycode 'KEY_LEFTALT')"
    f_code="$(_keycode "KEY_F${tty_number}")"

    _kill_flatpaks
    command -v playerctl &>/dev/null && playerctl pause
    echo "[${0##*/}] Switched TTY to TTY ${tty_number}"

    ydotool key "${ctrl}:1" "${alt}:1" "${f_code}:1" "${f_code}:0" "${alt}:0" "${ctrl}:0"
}

menu_1="$(
    printf '%s\n' \
        "${actions[shutdown]}" \
        "${actions[reboot]}" \
        "${actions[sleep]}" \
        "${actions[advanced]}" \
        "${actions[logout]}" | rofi -dmenu
)"
echo "$menu_1"

case "${menu_1:-}" in
"${actions[shutdown]}")
    _kill_flatpaks
    systemctl poweroff
    ;;
"${actions[reboot]}")
    _kill_flatpaks
    systemctl reboot
    ;;
"${actions[sleep]}")
    systemctl sleep
    ;;
"${actions[advanced]}")
    menu_2="$(printf '%s\n' "$advanced_actions_str" | rofi -dmenu)"
    case "${menu_2:-}" in
    "${advanced_actions[tty]}")
        _tty_switch
        ;;
    "${advanced_actions[uefi]}")
        systemctl reboot --firmware-setup
        ;;
    "${advanced_actions[hibernate]}")
        systemctl hibernate
        ;;
    *)
        echo "Error, advanced action not specified"
        exit 1
        ;;
    esac
    ;;
"${actions[logout]}")
    _kill_flatpaks
    loginctl kill-session "$XDG_SESSION_ID"
    ;;
*)
    echo "Error, action not specified"
    exit 1
    ;;
esac
