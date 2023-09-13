#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

distrobox_script="command -v pacman >/dev/null 2>&1 && sudo pacman -Syu;
command -v dnf >/dev/null 2>&1 && sudo dnf upgrade --refresh;
command -v apt >/dev/null 2>&1 && sudo apt update && sudo apt upgrade;"

if command -v distrobox &>/dev/null; then
    boxes="$(distrobox ls --no-color | cut -d '|' -f 2 | tail -n '+2' | sed 's/^[ ]*//g ; s/[ ]*$//g')"
    for i in $boxes; do
        echo "entering distrobox $i"
        distrobox-enter -n "$i" -- /bin/sh -c "$distrobox_script"
    done
fi
