#!/usr/bin/bash

hyprlib='/usr/lib64/hyprland'

plugins=(
    "$HOME/.local/src/hyprfocus/hyprfocus.so"
    "$hyprlib/libborders-plus-plus.so"
)

for i in "${plugins[@]}"; do
    echo "$i"
    hyprctl plugin load "$i"
done

