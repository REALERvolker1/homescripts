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
    ;;
*'xsessions'*)
    echo "$desktop_exec"
    ;;
*)
    echo shell
    ;;
esac
