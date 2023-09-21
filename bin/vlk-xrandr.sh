#!/usr/bin/bash
# xrandr script so I don't ever have to use xlayoutdisplay again
set -euo pipefail
IFS=$'\n\t'

PRIMARY='eDP-1'
# my hardware has an interesting quirk where if my external monitor is
# plugged into my dedicated GPU port, it does not reduce the refresh rate
# of my primary monitor.

NORATEREDUCE=('HDMI-1-0' 'DP-1-0')

xrandr_info="$(
    randr="$(xrandr 2>/dev/null)"
    currenthead=''
    echo "$randr" | while read -r line; do
        if echo "$line" | grep -q '^[a-zA-Z]'; then
            echo "$line"
        fi
    done
)"

echo "$xrandr_info"

# for i in $(xrandr | grep ' connected' | cut -d ' ' -f 1); do
#     echo "=$i="
# done
