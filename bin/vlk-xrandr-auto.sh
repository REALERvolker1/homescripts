#!/usr/bin/dash
# xrandr script so I don't ever have to use xlayoutdisplay again
set -eu
IFS='
'
RANDRSCRIPT="vlk-xrandr.sh"
export STATEPATH="${XDG_RUNTIME_DIR:-/tmp}/vlk-xrandr-state"

if command -v xev >/dev/null; then
    echo "[${0##*/}] monitoring for 'XRROutputChangeNotifyEvent'"
    if ! touch -- "$STATEPATH"; then
        echo "Could not make a file at STATEPATH '$STATEPATH'"
        exit 1
    fi
else
    echo "Error, dependency 'xev' not found!"
    exit 1
fi

$RANDRSCRIPT

xev -root -event randr | grep --line-buffered 'XRROutputChangeNotifyEvent' | while read -r line; do
    if [ "$args" != "$(cat "$STATEPATH")" ]; then
        $RANDRSCRIPT
        echo "$args" >"$STATEPATH"
    fi
done
