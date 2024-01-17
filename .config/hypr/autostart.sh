#!/usr/bin/bash

[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && exit 69

# [ -f "$HOME/.xsession-errors" ] && rm "$HOME/.xsession-errors" &
autostart-remove.sh &

autostart-dbus-activation-env.sh &
xhost +local: &
autostart-keyring.sh &
autostart-polkit.sh &

ydotoold &
#asusctl -c 80 &

#vlkbg.sh &
autostart-gammastep.sh &
#dunst &
mako &
hyprpaper &

# barcfg
waybar &
nm-applet &
(
    sleep 5
    firewall-applet
) &

set-cursor-theme.sh --session &
steam-symlink-unfucker.sh &
pointer.sh -n &
#pointer.sh -um &
pmgmt.sh --monitor &
#scratchpad_terminal.sh &

autostart-clipboard.sh &

hyprpm reload &

wait
