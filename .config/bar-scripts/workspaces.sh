#!/usr/bin/dash

case "$1" in
    '--listen')
        [ -n "$I3SOCK" ] && exec "$XDG_CONFIG_HOME/bar-scripts/i3workspaces/target/release/i3workspaces"
    ;; '--switch')
        [ -n "$I3SOCK" ] && exec i3-msg "workspace ${2:-10}"
    ;;
esac
