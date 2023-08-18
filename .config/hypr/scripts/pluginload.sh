#!/usr/bin/bash

hyprlib='/usr/lib64/hyprland'

plugins=(
    "$HOME/.local/src/hyprfocus/hyprfocus.so"
    "$hyprlib/libborders-plus-plus.so"
    "$hyprlib/libcsgo-vulkan-fix.so"
    #"$HOME/.local/src/hy3/build/libhy3.so"
)

for i in "${plugins[@]}"; do
    echo "$i"
    hyprctl plugin load "$i"
done

