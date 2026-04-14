#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

declare -a workspaces=()
declare sel

sel="$(zenity --forms --add-entry='Add New Workspace')"
sel="${sel//[[:space:]]/}"

notif() {
    echo "Notification:" "$@"
    notify-send -a "${0##*/}" 'Workspace notification' "$@" &
    disown
}

if [[ $sel =~ ^[0-9]+$ ]]; then
    notif "Moving active client to workspace $sel in 2 seconds. TODO: Use slurp for a selector and hyprctl -j clients"
    sleep 2
    exec hyprctl dispatch movetoworkspace "$sel"
else
    notif "Invalid workspace number: '$sel'"
fi
