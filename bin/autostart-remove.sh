#!/usr/bin/dash

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    for i in "$HOME/.xsession-errors" "$HOME/.Xauthority"; do
        [ -f "$i" ] && rm "$i"
    done
fi

[ -f "$HOME/.yarnrc" ] && rm "$HOME/.yarnrc"
