#!/usr/bin/sh

systemctl --user import-environment DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
dbus-update-activation-environment --systemd --all

# SIGCHILD
# exit 20
