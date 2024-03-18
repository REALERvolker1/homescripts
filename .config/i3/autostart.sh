#!/usr/bin/env bash

[ -z "${I3SOCK:-}" ] && exit 69

exec autostart-vlk-session.sh

exit

(
    autostart-dbus-activation-env.sh
    # systemctl --user start user-graphical-session.target
    # systemctl --user start xorg.target
) &
xrdb -merge "$XRESOURCES" &
# vlk-xrandr.sh --monitor &
vlk-xrandr.sh &
[ -f "$XDG_CONFIG_HOME/nvidia/settings" ] && nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" &

# autostart-polkit.sh &
# autostart-keyring.sh &
# autostart-clipboard.sh &

(
    pkill -ef 'xfce4-clipman'
    xfce4-clipman
) &

#dunst &
#xsettingsd &
# run sudo chown "$USER" /dev/uinput
# ydotoold &
# steam-symlink-unfucker.sh &
# autostart-gammastep.sh &
# volbright.sh --brightness --volume --keyboard

xset -dpms &
# xss-lock -l "vlklock.sh" &
# pmgmt.sh --monitor &
# (
#     killall xplugd
#     xplugd
# ) &

#pointer.sh -um &

numlockx &
pointer.sh -n &
#(
#    mo="$(xinput | grep -oP '↳ Glorious Model O\s+id=\K[0-9]+')"
#    ret="$?"
#    ((ret)) || xinput set-prop "$mo" 'libinput Accel Profile Enabled' 0 1 0
#) &
(
    xmodmap -e "clear lock"
    xmodmap -e "keycode 66 = Escape NoSymbol Escape"
) &

# nm-applet &
#firewall-applet &
#flameshot &

picom &
# flashfocus &
vlkbg.zsh &

#(
# crashes all the time, doesn't like me very much but will bend to my will eventually
#    while :; do
#        autotiling-rs
#    done
#) &
autotiling-rs &
#scratchpad_terminal.sh &
wait
