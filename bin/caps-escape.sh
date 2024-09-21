#!/usr/bin/bash
set -euo pipefail

command -v xmodmap &>/dev/null || {
    echo "Error, missing required dependency 'xmodmap'"
    exit 1
}

if [[ -n ${WAYLAND_DISPLAY-} ]]; then
    echo "Error, this script does not work on wayland!"
    exit 2
fi

xmodmap -e "clear lock"
xmodmap -e "keycode 66 = Escape NoSymbol Escape"
