#!/usr/bin/bash

[ -z "${I3SOCK:-}" ] && exit 69

autostart-dbus-activation-env.sh &
xrdb -merge "$XRESOURCES" &
xlayoutdisplay --quiet &

autostart-polkit.sh &
autostart-keyring.sh &
autostart-clipboard.sh &

dunst &
xsettingsd &
ydotoold &
steam-symlink-unfucker.sh &
autostart-gammastep.sh &

xset -dpms &
xss-lock -l "vlklock.sh" &
pmgmt.sh &
(
    killall xplugd
    xplugd
) &

numlockx &
pointer.sh -n &
(
    xmodmap -e "clear lock"
    xmodmap -e "keycode 66 = Escape NoSymbol Escape"
) &

nm-applet &
flameshot &

picom &
flashfocus &
