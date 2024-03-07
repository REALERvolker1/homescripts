#!/usr/bin/env dash
set -eu

: $HYPRLAND_INSTANCE_SIGNATURE

LOCKER=vlklock.sh

if command -v "$LOCKER"; then
    "$LOCKER"
else
    notify-send -a "${0##*/}" Error "Error locking the screen! Missing locker '$LOCKER'"
fi
