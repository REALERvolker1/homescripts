#!/usr/bin/bash

# Get the window ID of the currently focused window
window_id=$(xprop -root _NET_ACTIVE_WINDOW | awk -F' ' '{print $5}')

# Get the window title using xprop
window_title=$(xprop -id "$window_id" | awk -F'"' '/_NET_WM_NAME/ {print $2}')

echo "$window_title"

if [ -n "$I3SOCK" ]; then
    i3-msg -t subscribe -m '[ "window" ]' | while read -r line; do
        title="$(echo "$line" | jq -r '.container.window_properties.title')"
        # class="$(echo "$line" | jq -r '.container.window_properties.class')"
        [ -n "$title" ] && echo "$title" #  :: $class"
    done
fi
