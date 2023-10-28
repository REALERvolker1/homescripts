#!/usr/bin/env bash

[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && exit 69

# [ -f "$HOME/.xsession-errors" ] && rm "$HOME/.xsession-errors" &
autostart-remove.sh &

autostart-dbus-activation-env.sh &
xhost +local: &
autostart-keyring.sh &
autostart-polkit.sh &

ydotoold &
asusctl -c 80 &

# "$XDG_CONFIG_HOME/hypr/scripts/pluginload.sh" &
#vlkbg.sh &
autostart-gammastep.sh &
dunst &
hyprpaper &

# barcfg
waybar &
nm-applet &

set-cursor-theme.sh --session &
steam-symlink-unfucker.sh &
# pointer.sh -n &
pointer.sh -um &
pmgmt.sh --monitor &
#scratchpad_terminal.sh &

autostart-clipboard.sh &
