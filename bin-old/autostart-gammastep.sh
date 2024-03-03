#!/usr/bin/env dash

killall gammastep

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    gammastep_mode='wayland'
elif [ -n "${DISPLAY:-}" ]; then
    gammastep_mode='randr'
fi

exec gammastep -P -m "$gammastep_mode"
