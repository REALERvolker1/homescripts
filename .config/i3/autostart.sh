#!/usr/bin/bash

[ -z "${I3SOCK:-}" ] && exit 69

autostart-dbus-activation-env.sh &
xrdb -merge "$XRESOURCES" &
# vlk-xrandr.sh --monitor &
vlk-xrandr.sh &
[ -f "$XDG_CONFIG_HOME/nvidia/settings" ] && nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" &

autostart-polkit.sh &
autostart-keyring.sh &
autostart-clipboard.sh &

dunst &
xsettingsd &
# run sudo chown "$USER" /dev/uinput
ydotoold &
steam-symlink-unfucker.sh &
autostart-gammastep.sh &
# volbright.sh --brightness --volume --keyboard

xset -dpms &
xss-lock -l "vlklock.sh" &
pmgmt.sh --monitor &
# (
#     killall xplugd
#     xplugd
# ) &

#pointer.sh -um &

numlockx &
pointer.sh -n &
(
    mo="$(xinput | grep -oP '↳ Glorious Model O\s+id=\K[0-9]+')"
    ret="$?"
    ((ret)) || xinput set-prop "$mo" 'libinput Accel Profile Enabled' 0 1 0
) &
(
    xmodmap -e "clear lock"
    xmodmap -e "keycode 66 = Escape NoSymbol Escape"
) &

#seapplet & # piece of shit that doesn't work
nm-applet &
flameshot &

picom &
#conda run -n i3 flashfocus &
flashfocus &
vlkbg.sh &
autotiling-rs &
#scratchpad_terminal.sh &
