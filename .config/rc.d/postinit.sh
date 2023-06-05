#!/usr/bin/bash

xrdb -merge "$XRESOURCES" &
/usr/libexec/xfce-polkit &

case "$VLK_SESSION_TYPE" in
    'xorg')
        nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" -l &
        dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY
        systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

        numlockx &
        pointer.sh -n &
        xmodmap -e "clear lock"
        xmodmap -e "keycode 66 = Escape NoSymbol Escape"

        xlayoutdisplay &

    ;;
    'wayland')
    ;;
    *)
    ;;
esac
$VLK_SESSION_EXEC
wait
