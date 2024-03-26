#!/usr/bin/env bash
# I have migrated a lot of this stuff to a systemd user target.
[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && exit 69

exec autostart.sh

exit

autostart-remove.sh &

(
    autostart-dbus-activation-env.sh
    # systemctl --user start user-graphical-session.target
    # systemctl --user start wayland.target
) &

autostart-gammastep.sh &

xhost +local: &
# xhost +local:root:
autostart-keyring.sh &
autostart-polkit.sh &

pgrep ydotoold &>/dev/null || ydotoold &
#asusctl -c 80 &

dunst &
hyprpaper &

# barcfg
waybar &

set-cursor-theme.sh --session &
steam-symlink-unfucker.sh &
# hyprpointer normalize &
pgrep hyprpointer || hyprpointer status-monitor &
#pmgmt.sh --monitor &

pgrep nm-applet &>/dev/null || nm-applet &

# pgrep firewall-applet &>/dev/null || (
#     sleep 5
#     exec firewall-applet
# ) &

hyprpm reload &

wait
