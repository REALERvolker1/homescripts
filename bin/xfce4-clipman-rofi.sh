#!/usr/bin/env bash
echo -n "$(\
    tail -n +2 "$XDG_CACHE_HOME/xfce4/clipman/textsrc" \
    | sed 's/^texts=//g ; s/\\;/𐖘/g ; s/;/\n/g ; s/𐖘/;/g ; s/\\\\/\\/g' \
    | grep -v '^$' \
    | rofi -dmenu -mesg "xfce4-clipman history" \
    | sed 's/\n$//g'\
)" \
    | xclip -selection clipboard
