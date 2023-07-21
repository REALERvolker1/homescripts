#!/bin/sh

sessions="$(

    oldifs="$IFS"
    IFS=':'
    for i in ${XDG_DATA_DIRS:-/usr/share}; do
        xdir="$i/xsessions"
        wdir="$i/wayland-sessions"
        IFS="$oldifs"
        for j in \
            "$xdir"/* \
            "$wdir"/*; do
            case "$j" in
            *'*')
                continue
                ;;
            esac
            echo "$j"
        done
        IFS=':'
    done
    IFS="$oldifs"

)"

# My personal preferences
sessions="$(echo "$sessions" | grep -v 'i3-with-shmlog.desktop' | tac)"

selection="$(echo "$sessions" | fzf --height="$(echo "$(echo "$sessions" | wc -l)" + 2 | bc)")"

#echo "$selection"

selection_file="$(grep -v '^#' "$selection")"
desktop_name="$(echo "$selection_file" | grep -m 1 -oP '^Name=\K[^ ]*')"
desktop_exec="$(echo "$selection_file" | grep -m 1 -oP '^Exec=\K[^ ]*')"

echo "$desktop_name"

case "$selection" in
*'wayland-sessions'*)
    echo "$desktop_exec"

    export XDG_CURRENT_DESKTOP="$desktop_name"
    export XDG_SESSION_DESKTOP="$desktop_name"
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
    (eval $desktop_exec) >>"$ERRFILE"
    ;;
*'xsessions'*)
    for i in \
        stx \
        sx \
        startx; do
        if command -v "$i" >/dev/null; then
            cmdexec="$i"
            #break
        else
            continue
        fi
    done
    eval $cmdexec "$desktop_exec"
    # echo "$desktop_exec"
    ;;
*)
    echo shell
    ;;
esac
