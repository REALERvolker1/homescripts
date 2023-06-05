#!/usr/bin/dash

set -eu

RC="${XDG_CONFIG_HOME:-$HOME/.config}/rc.d"
[ ! -d "$RC" ] && echo "Error, '$RC' does not exist!" && exit 1

eval "$("$RC/chooser.sh")"

printf '%s\t%s\n' \
    'VLK_SESSION_NAME' "${VLK_SESSION_NAME:-None}" \
    'VLK_SESSION_TYPE' "$VLK_SESSION_TYPE" \
    'VLK_SESSION_EXEC' "$VLK_SESSION_EXEC"
printf 'export%s=%s\n' \
    'VLK_SESSION_NAME' "${VLK_SESSION_NAME:-}" \
    'VLK_SESSION_TYPE' "$VLK_SESSION_TYPE" \
    'VLK_SESSION_EXEC' "$VLK_SESSION_EXEC" > "$XDG_RUNTIME_DIR/vlk-$XDG_SESSION_ID.env"

export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-VLK_SESSION_NAME}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-VLK_SESSION_NAME}"

export YDOTOOL_SOCKET='/tmp/.ydotool_socket'

#eval "$(grep -v '^#' "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" | sed 's|^|export |g')"
cursor_theme="$(grep -m 1 -oP '^Inherits=\K.*$' /usr/share/icons/default/index.theme)"
export XCURSOR_THEME="$cursor_theme"
export XCURSOR_SIZE=24

export ERRFILE="$XDG_RUNTIME_DIR/vlk-session-errors"

eval "$("$HOME/.local/libexec/hardcoded-keyring-unlocker" 2>/dev/null | grep '^[A-Z]' | sed 's/^/export /g')"

case "$VLK_SESSION_TYPE" in
    'xorg')
        unset WAYLAND_DISPLAY
        export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
        (
            if command -v mini-startx.sh >/dev/null; then
                mini-startx.sh --vlk-session="$VLK_SESSION_EXEC" >> "$ERRFILE"
                #mini-startx.sh "$XINITRC" >> "$ERRFILE"
            else # "$RC/postinit.sh $VLK_SESSION_EXEC"
                startx "$VLK_SESSION_EXEC"
            fi
        )
    ;;
    'wayland')
        export XDG_SESSION_TYPE='wayland'

        export QT_QPA_PLATFORM='wayland;xcb'
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export GDK_BACKEND='wayland,x11'
        export SDL_VIDEODRIVER='wayland'
        export CLUTTER_BACKEND='wayland'
        export _JAVA_AWT_WM_NONREPARENTING=1
        export MOZ_ENABLE_WAYLAND=1
        (
            $VLK_SESSION_EXEC
        )
    ;;
    *)
        exec $VLK_SESSION_EXEC
    ;;
esac
wait

