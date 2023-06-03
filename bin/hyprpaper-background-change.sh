#!/usr/bin/bash

background_folder="$HOME/Pictures/fedora-backgrounds"
# background_folder="$XDG_DATA_HOME/backgrounds"
selection="$(echo "$background_folder"/*.jpg | tr ' ' '\n' | shuf | head -n 1)"
hyprctl hyprpaper preload "$selection"

echo "$selection"

monitors="$(hyprctl monitors | grep -oP '^Monitor \K[^ ]*')"

for monitor in $monitors; do
    hyprctl hyprpaper wallpaper "$monitor,$selection"
done

