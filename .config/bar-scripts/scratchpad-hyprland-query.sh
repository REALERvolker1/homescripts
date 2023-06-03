#!/usr/bin/dash

handle () {
    local event
    local windows
    event="$(echo "$1" | cut -d '>' -f 1)"
    if [ "$event" = "activewindow" ]; then
        windows="$(hyprctl workspaces -j | jq '.[] | select(.name=="special:scratchpad") | .windows')"
        [ -z "$windows" ] && windows=0
        echo "󱂬 $windows"
    fi
}
handle "activewindow"

socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
