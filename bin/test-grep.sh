#!/usr/bin/dash

active_monitor="$(hyprctl activeworkspace -j | jq -r '.monitor')"
active_window="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
sleep 1
# grim -g "$(slurp)"
# grim -o "$active_monitor" - | swappy -f -
# grim
grim -g
