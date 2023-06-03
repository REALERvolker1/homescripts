#!/usr/bin/dash
# shellcheck disable=SC2064
unset MAILCHECK
echo "Current login shell: '${SHELL##*/}'"
SESSIONS="WLR\tHyprland
X11\ti3
X11\topenbox-session
SH\tzsh
SH\tbash"

selection="$(echo "$SESSIONS" | fzf --height=7)"
command="$(echo "$selection" | cut -f 2)"
session_type="$(echo "$selection" | cut -f 1)"

cursor_theme="$(grep -m 1 -oP '^Inherits=\K.*$' /usr/share/icons/default/index.theme)"
export XCURSOR_THEME="$cursor_theme"
export YDOTOOL_SOCKET='/tmp/.ydotool_socket'
export VLKDM_SESSION="$command"

case "$command" in
    'Hyprland')
        export XDG_CURRENT_DESKTOP='Hyprland'
        export XDG_SESSION_DESKTOP='Hyprland'
    ;;
    'i3')
        export XDG_CURRENT_DESKTOP='i3'
        export XDG_SESSION_DESKTOP='i3'
    ;;
    'openbox'*)
        export XDG_CURRENT_DESKTOP='openbox'
        export XDG_SESSION_DESKTOP='openbox'
    ;;
esac

fake_xinitrc () {
    echo "started fake xinitrc with $VLKDM_SESSION at $(date +'%X %x')"

    xrdb -merge "$XRESOURCES" &
    /usr/libexec/xfce-polkit &
    nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" -l &
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY
    systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

    #xset -dpms &
    numlockx &
    pointer.sh -n &
    xmodmap -e "clear lock"
    xmodmap -e "keycode 66 = Escape NoSymbol Escape"

    xlayoutdisplay &

    if [ "$VLKDM_SESSION" = 'openbox-session' ]; then
        (while true; do tint2; done) &
        volumeicon &
    fi

    exec "$command"
}
eval "$("$HOME/.local/libexec/hardcoded-keyring-unlocker" 2>/dev/null | grep '^[A-Z]' | sed 's/^/export /g')"
case "$session_type" in
    'WLR')
        export XDG_SESSION_TYPE='wayland'

        export QT_QPA_PLATFORM='wayland;xcb'
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export GDK_BACKEND='wayland,x11'
        export SDL_VIDEODRIVER='wayland'
        export CLUTTER_BACKEND='wayland'
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1

        #initrc
        #dbus-update-activation-environment --systemd DISPLAY XAUTHORITY WAYLAND_DISPLAY
        exec "$command"
    ;;
    'X11')
        # thanks a ton, https://github.com/Earnestly/sx
        #unset DBUS_SESSION_BUS_ADDRESS
        #unset SESSION_MANAGER
        #command="dbus-run-session -- '$command'"
        stty="$(stty -g)"
        tty="$(tty)"
        tty="${tty#/dev/tty}"
        cleanup() {
            if [ "$server" ] && kill -0 "$server" 2> /dev/null; then
                kill "$server"
                wait "$server"
                xorg=$?
            fi
            if ! stty "$stty"; then
                stty sane
            fi
            xauth remove :"$tty"
        }

        export XINITRC="${XINITRC:-$HOME/.xinitrc}"
        export XAUTHORITY="${XAUTHORITY:-$XDG_RUNTIME_DIR/Xauthority}"
        touch -- "$XAUTHORITY"

        trap 'cleanup; exit "${xorg:-0}"' EXIT
        for signal in HUP INT QUIT TERM; do
            trap "cleanup; trap - $signal EXIT; kill -s $signal $$" "$signal"
        done
        trap 'DISPLAY=:$tty "fake_xinitrc" & wait "$!"' USR1 # ${@:-$XINITRC}
        #trap 'DISPLAY=:$tty "$command" & wait "$!"' USR1 # ${@:-$XINITRC}

        xauth add :"$tty" MIT-MAGIC-COOKIE-1 "$(mcookie)" # $(od -An -N16 -tx /dev/urandom | tr -d ' ')
        (trap '' USR1 && exec Xorg :"$tty" vt"$tty" -keeptty -noreset -auth "$XAUTHORITY") &
        server=$!
        wait "$server"
    ;;
    *)
        exec "$command"
    ;;
esac
