#!/usr/bin/bash

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    platform=xorg
else
    platform=wayland
fi
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    session=hyprland
elif [ -n "${I3SOCK:-}" ]; then
    session=i3
fi

if [ "${platform}" != 'xorg' ] && [ "${platform}" != 'wayland' ]; then
    echo "Error, platform is undefined!"
    exit 2
fi

_exec () {
    local comm="${1:?Error, please enter a command!}"
    if command -v "$comm" &>/dev/null || [ -x "$comm" ]; then
        sh -c "$@"
    fi
}
_execx () {
    [ "${platform:-}" = 'xorg' ] && _exec "$@"
}
_execw () {
    [ "${platform:-}" = 'wayland' ] && _exec "$@"
}

__dbus_systemd_env () {
    _execx dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
    _execw dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
    _execw systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    _execw xhost +local:
}

__polkit_agent () {
    for i in \
        '/usr/libexec/xfce-polkit' \
        '/usr/lib/xfce-polkit/xfce-polkit' \
        '/usr/libexec/polkit-mate-authentication-agent-1' \
        '/usr/lib/mate-polkit/polkit-mate-authentication-agent-1' \
        '/usr/libexec/polkit-gnome-authentication-agent-1' \
        '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' \
        '/usr/libexec/lxqt-policykit-agent' \
        'lxpolkit'; do
        _exec "$i" &
    done
}

__notification_daemon () {
    killall dunst
    _exec dunst &
}

__keyring_daemon () {
    #~/.local/lib/hardcoded-keyring-unlocker
    _exec gnome-keyring-daemon &
}

__input_config () {
    _exec pointer.sh -n
    _execx numlockx
    _execx xmodmap -e "clear lock"
    _execx xmodmap -e "keycode 66 = Escape NoSymbol Escape"
}

__statusbar () {
    _execw waybar &
    _exec nm-applet &
}

#volbright.sh --brightness --volume --keyboard &


case "${platform:-}" in
    'xorg')
        xrdb -merge "$XRESOURCES" &
        xsettingsd &
        xlayoutdisplay --quiet &
        ;;
    'wayland')
        xhost +local: &
        ;;
    *)
       ;;
esac




