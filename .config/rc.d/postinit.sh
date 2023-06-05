#!/usr/bin/bash

xrdb -merge "$XRESOURCES" &
/usr/libexec/xfce-polkit &

dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

pointer.sh -n &

case "$2" in
    '--bloat')
        /usr/libexec/geoclue-2.0/demos/agent &
    ;;
    *)
    ;;
esac

case "$1" in
    '--xorg')
        nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" -l &

        numlockx &
        xmodmap -e "clear lock"
        xmodmap -e "keycode 66 = Escape NoSymbol Escape"

        xlayoutdisplay &

    ;;
    '--wayland')
        gammastep -P -m wayland &
        waybar &
    ;;
    *)
    ;;
esac
wait
