#!/usr/bin/dash

if [ -n "${WAYLAND_DISPLAY-}" ]; then
    exec gammastep -P -m wayland
elif [ -n "${DISPLAY-}" ]; then
    exec gammastep -P -m randr
fi
