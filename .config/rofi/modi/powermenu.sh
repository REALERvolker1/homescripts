#!/usr/bin/env bash
# script by vlk

case "$@" in
    "Shut Down")
        coproc ( systemctl poweroff &>/dev/null )
        exit 0
    ;; "Restart")
        coproc ( systemctl reboot &> /dev/null )
        exit 0
    ;; "Log Out")
        coproc ( loginctl kill-session "${XDG_SESSION_ID}" &> /dev/null )
        exit 0
    ;; "Suspend")
        coproc ( systemctl suspend &>/dev/null )
        exit 0
    ;; "UEFI Reboot")
        coproc ( systemctl reboot --firmware-setup &>/dev/null )
        exit 0
    #;; "Lock")
    #    coproc ( sh -c "${XDG_LOCKSCREEN:-vlklock.sh}" &>/dev/null )
    #    exit 0
    ;;
esac
printf "
\0message\x1fHow would you like to end your session, $USER?
\0urgent\x1f1,4
\0active\x1f2
Log Out\0icon\x1f<span color='${ROFI_NORMAL:-#FFFFFF}'></span>
Restart\0icon\x1f<span color='${ROFI_URGENT:-#000000}'></span>
Suspend\0icon\x1f<span color='${ROFI_URGENT:-#000000}'>⏼</span>
UEFI Reboot\0icon\x1f<span color='${ROFI_NORMAL:-#FFFFFF}'></span>
Shut Down\0icon\x1f<span color='${ROFI_URGENT:-#000000}'>⏻</span>
"
#Lock\0icon\x1f<span color='${ROFI_NORMAL:-#FFFFFF}'>󰍁</span>

