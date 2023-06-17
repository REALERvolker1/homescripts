# shellcheck shell=dash
. '/home/vlk/bin/vlkenv'

loginctl list-sessions --no-pager

start_hyprland () {
    export XDG_CURRENT_DESKTOP='Hyprland'
    export XDG_SESSION_DESKTOP='Hyprland'
    export XDG_SESSION_TYPE='wayland'
        
    export QT_QPA_PLATFORM='wayland;xcb'
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GDK_BACKEND='wayland,x11'
    export SDL_VIDEODRIVER='wayland'
    export CLUTTER_BACKEND='wayland'
    export _JAVA_AWT_WM_NONREPARENTING=1
    export MOZ_ENABLE_WAYLAND=1

    ERRFILE="${ERRFILE:-$XDG_RUNTIME_DIR/errfile-$XDG_CURRENT_DESKTOP}"
    [ -f "$ERRFILE" ] && rm "$ERRFILE"
    touch -- "$ERRFILE"
    ( Hyprland ) >> "$ERRFILE"
}

export XCURSOR_THEME="$(grep -m 1 -oP '^Inherits=\K.*$' /usr/share/icons/default/index.theme)"
export XCURSOR_SIZE='24'

case "$-" in
    *'i'*)
        if [ "$TERM" = 'linux' ] && [ "$(tty)" = '/dev/tty1' ]; then
            start_hyprland
            #exec vlkdm-login-profile.sh
        fi
    ;;
    *)
        echo 'non-interactive'
    ;;
esac
#[ "$TERM" = 'linux' ] && expr "$-" : '.*i' >/dev/null && exec vlkdm-login-profile.sh
