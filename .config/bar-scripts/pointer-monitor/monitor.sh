#!/usr/bin/bash
# This script is a workaround so that I don't get too many inotify watches when I reloaded my waybar too much
if ! command -v 'pointer.sh' &>/dev/null; then
    echo "Error, you must have pointer.sh in your PATH"
    exit 1
fi

export TOUCHPAD_STATUS="$XDG_RUNTIME_DIR/touchpad-statusfile"
if [ ! -f "$TOUCHPAD_STATUS" ]; then
    pointer.sh -n #&
    # disown
fi

exec "$(dirname "$0")/target/release/pointer-monitor"
