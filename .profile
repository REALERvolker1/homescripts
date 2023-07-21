# shellcheck shell=dash
## shellcheck disable=SC2155
#export CURRENT_DISTRO="$(grep -oP '^NAME="\K[^ ]*' /etc/os-release)"
. '/home/vlk/bin/vlkenv'

loginctl list-sessions --no-pager

export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"

start_hyprland() {
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

    # WLR_NO_HARDWARE_CURSORS=1
    #~/.local/lib/hardcoded-keyring-unlocker

    ERRFILE="${ERRFILE:-$XDG_RUNTIME_DIR/errfile-$XDG_CURRENT_DESKTOP}"
    [ -f "$ERRFILE" ] && rm "$ERRFILE"
    touch -- "$ERRFILE"
    (Hyprland) >>"$ERRFILE"
}
eval $(set-cursor-theme.sh --shell-eval)

case "$0" in
*'bash'*)
    unset MAILCHECK
    ;;
esac

case "$-" in
*'i'*)
    if [ "$TERM" = 'linux' ] && [ "$(tty)" = '/dev/tty1' ]; then
        start_hyprland
        #exec vlkdm-login-profile.sh
    else
        . "${BDOTDIR:-$HOME}/.bashrc"
    fi
    ;;
*)
    echo 'non-interactive'
    ;;
esac
#[ "$TERM" = 'linux' ] && expr "$-" : '.*i' >/dev/null && exec vlkdm-login-profile.sh
