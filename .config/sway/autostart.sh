#!/usr/bin/bash

[ -z "${SWAYSOCK:-}" ] && exit 69

autostart-remove.sh &
autostart-dbus-activation-env.sh &
xhost +local: &
autostart-keyring.sh &
autostart-polkit.sh &

ydotoold &
asusctl -c 80 &

autostart-gammastep.sh &
dunst &
# hyprpaper &

nm-applet &

set-cursor-theme.sh --session &
steam-symlink-unfucker.sh &

pointer.sh -n &
pmgmt.sh --monitor &
# scratchpad_terminal.sh &

autostart-clipboard.sh &
autotiling-rs &
scratchpad_terminal.sh &
