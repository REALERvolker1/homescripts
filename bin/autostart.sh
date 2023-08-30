#!/usr/bin/bash

set -u

for i in "$@"; do
    i_opt="${i#*=}"
    case "$i" in
        '--platform='*)
            platform="$i_opt"
            ;;
        '--session='*)
            session="$i_opt"
            ;;
    esac
done

dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP &
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &



