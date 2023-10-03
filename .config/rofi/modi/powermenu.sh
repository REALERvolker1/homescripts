#!/usr/bin/env bash
# script by vlk

_kill_flatpaks() {
    command -v flatpak &>/dev/null || return
    flatpak ps 2>/dev/null | cut -f 3 | while read -r line; do
        flatpak kill "$line" &>/dev/null
    done
}

case "$@" in
"Shut Down")
    coproc (
        _kill_flatpaks
        systemctl poweroff &>/dev/null
    )
    exit 0
    ;;
"Restart")
    coproc (
        _kill_flatpaks
        systemctl reboot &>/dev/null
    )
    exit 0
    ;;
"Log Out")
    coproc (loginctl kill-session "${XDG_SESSION_ID}" &>/dev/null)
    exit 0
    ;;
"Suspend")
    coproc (systemctl suspend &>/dev/null)
    exit 0
    ;;
"UEFI Reboot")
    coproc (
        _kill_flatpaks
        systemctl reboot --firmware-setup &>/dev/null
    )
    exit 0
    ;;
esac
printf "
\0message\x1fHow would you like to end your session, $USER?
\0urgent\x1f1,4
\0active\x1f2
Log Out\0icon\x1f<span color='${ROFI_ICON_NORMAL:-#FFFFFF}'></span>
Restart\0icon\x1f<span color='${ROFI_ICON_URGENT:-#000000}'></span>
Suspend\0icon\x1f<span color='${ROFI_ICON_ACTIVE:-#000000}'>󰤄</span>
UEFI Reboot\0icon\x1f<span color='${ROFI_ICON_NORMAL:-#FFFFFF}'>󰍛</span>
Shut Down\0icon\x1f<span color='${ROFI_ICON_URGENT:-#000000}'>󰐥</span>
"
