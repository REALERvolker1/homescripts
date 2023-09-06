#!/bin/sh

case "${XDG_SESSION_TYPE:-}" in
'wayland')
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GDK_BACKEND='wayland,x11'
    export SDL_VIDEODRIVER='wayland'
    export CLUTTER_BACKEND='wayland'
    export _JAVA_AWT_WM_NONREPARENTING=1

    # export WLR_NO_HARDWARE_CURSORS=1
    ;;
'xorg')
    # dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    # systemctl --user import-environment DISPLAY XAUTHORITY
    # dbus-update-activation-environment --systemd DISPLAY XAUTHORITY
    # [ -z "$XAUTHORITY" ] && export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
    ;;
*)
    echo "Environment variable \$XDG_SESSION_TYPE not set!"
    ;;
esac
