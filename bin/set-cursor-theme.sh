#!/usr/bin/bash

set -euo pipefail

set_cursors () {
    local cursor="${1:?Error, please input a cursor theme}"
    local size="${2:?Error, please input a cursor size}"

    printf "Cursor %s: '\e[1m%s\e[0m'\n" 'theme' "$cursor" 'size' "$size"
    # gnome gsettings
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor"
        gsettings set org.gnome.desktop.interface cursor-size "$size"
        echo 'Cursors set in gsettings'
    fi
    # hyprland
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl setcursor "$cursor" "$size"
        echo 'Cursors set in hyprland'
    fi
    
    # X server resources
    if command -v xrdb >/dev/null; then
        # merge X resources if they are empty
        printf '%s\n' "$(xrdb -query | grep -vE '^Xcursor\.(theme|size)')" \
            "Xcursor.theme: $XCURSOR_THEME" \
            "Xcursor.size: $XCURSOR_SIZE" \
             | xrdb -load
        echo 'Cursors set in X server resources'
    fi

    # flatpak overrides
    if command -v flatpak >/dev/null; then
        flatpak override -u --env=XCURSOR_THEME="$cursor"
        flatpak override -u --env=XCURSOR_SIZE="$size"
        echo 'Cursors set in flatpak'
    fi

    # This doesn't work unless the file is sourced, but what the hell
    export XCURSOR_THEME="$cursor"
    export XCURSOR_SIZE="$size"
}

get_cursor_xdg () {
    local -a data_dirs=("$HOME/.icons/default/index.theme")
    local oldifs="$IFS"
    local IFS=':'
    local i
    # reverse the XDG dirs so the user choice takes preference
    for i in $XDG_DATA_DIRS; do
        data_dirs=("$i/icons/default/index.theme" "${data_dirs[@]}")
    done
    IFS="$oldifs"

    # look for cursor theme, if found, overwrite preference
    local swaptheme
    local cursortheme
    #local cursorfile
    for i in "${data_dirs[@]}"; do
        [ ! -f "$i" ] && continue
        if swaptheme="$(grep -m 1 -oP '^Inherits=\K.*$' "$i" 2>/dev/null)"; then
            cursortheme="$swaptheme"
            #cursorfile="$i"
        fi
    done

    # gracefully fall back to Adwaita cursors
    echo "${cursortheme:-Adwaita}"
}

get_cursor_size () {
    local size="${XCURSOR_SIZE:-24}"
    case "$size" in
        ''|*[!0-9]*) size=24 ;;
    esac
    echo "$size"
}

preferred_theme="$(get_cursor_xdg)"
preferred_size="$(get_cursor_size)"

action="${1:-}"
case "${action}" in
    '--shell-eval')
        printf "export %s='%s'\n" 'XCURSOR_THEME' "$preferred_theme" 'XCURSOR_SIZE' "$preferred_size"
        ;;
    '--session')
        set_cursors "$preferred_theme" "$preferred_size"
        ;;
    *)
        printf '%s\n' '' "Error, unknown option '$action'"\
            "--shell-eval   Print output to run through eval to get shell vars" \
            '    run `eval "$(set-cursor-theme.sh --shell-eval)"' \
            "--session      This is designed for setting the cursor in an interactive X or Wayland session" \
            "    put this in your session autostarts"
        exit 1
        ;;
esac
