#!/usr/bin/dash

handle () {
    local event
    event="$(echo "$1" | cut -d '>' -f 1)"
    if [ "$event" = "openwindow" ] || [ "$event" = "closewindow" ]; then
        xlsclients | wc -l
    fi
}

handle "openwindow"
socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
