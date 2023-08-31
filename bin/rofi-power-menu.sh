#!/usr/bin/env bash
# script by vlk
set -euo pipefail
IFS=$'\n\t'

declare -A actions
actions[logout]="Log Out"
actions[reboot]="Restart"
actions[sleep]="Sleep"
actions[shutdown]="Shut Down"

declare -A advanced_actions
advanced_actions[tty]="Switch active TTY"
advanced_actions[uefi]="UEFI reboot"
advanced_actions[hibernate]="Hibernate"

if command -v flatpak &>/dev/null; then
    declare -a unruly_flatpaks=(
        'com.valvesoftware.Steam'
        'com.discordapp.Discord'
    )
    _kill_flatpaks () {
        local grepstr="$(printf '%s|' "${unruly_flatpaks[@]}")"
        local unruly_procs="$(flatpak ps 2>/dev/null | grep -oE "(${grepstr:: -1})" | uniq)"
        if [ -n "$unruly_procs" ]; then
            echo "Unruly flatpaks detected. Killing them"
            for i in $unruly_procs; do
                flatpak kill "$i" &
            done
            wait
        fi
    }
fi

#_check_flatpaks

menu_1="$(printf '%s\n' "${actions[@]}" | rofi -dmenu)"
echo "$menu_1"


