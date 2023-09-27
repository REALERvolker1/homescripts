#!/usr/bin/bash

declare -A up

if command -v dnf &>/dev/null; then
    up[dnf]="$(dnf check-update)"
fi

# I don't know if this requires sudo
#if command -v yay &>/dev/null; then
#    up[yay]="$(yay -Sy &>/dev/null ; yay -Qu)"
#elif command -v pacman &>/dev/null; then
#    up[pacman]="$(pacman -Sy &>/dev/null ; pacman -Qu)"
#fi

if command -v flatpak &>/dev/null; then
    up[flatpak]="$(flatpak remote-ls --updates -a --columns=application,version)"
fi
if command -v cargo-install-update; then
    up[cargo]="$(cargo install-update -a -g --list)"
fi

