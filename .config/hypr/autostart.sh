#!/usr/bin/bash
# I have migrated a lot of this stuff to a systemd user target.
[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && exit 69

# [ -f "$HOME/.xsession-errors" ] && rm "$HOME/.xsession-errors" &
autostart-remove.sh &

(
    autostart-dbus-activation-env.sh
    systemctl --user start user-graphical-session.target
    systemctl --user start wayland.target
) &

xhost +local: &
# xhost +local:root:
#autostart-keyring.sh &
#autostart-polkit.sh &

#ydotoold &
#asusctl -c 80 &

#vlkbg.sh &
#autostart-gammastep.sh &
#dunst &
#mako &
hyprpaper &

# barcfg
waybar &
#nm-applet &
#(
#    sleep 5
#    firewall-applet
#) &

(
    sleep 3
    hyprshade auto
) &

set-cursor-theme.sh --session &
#steam-symlink-unfucker.sh &
# pointer.sh -n &
#pointer.sh -um &
#pmgmt.sh --monitor &
#scratchpad_terminal.sh &

autostart-clipboard.sh &

hyprpm reload &

wait
