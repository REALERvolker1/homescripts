#!/usr/bin/bash
set -Eeuo pipefail

if [[ -z ${WAYLAND_DISPLAY:-} && -z ${DISPLAY:-} ]]; then
    printf '%s\n' 'autostart.sh requires a graphical session.' >&2
    exit 1
fi

if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v uwsm >/dev/null && uwsm check is-active compositor-only; then
    # UWSM loads toolkit settings before the compositor and owns their cleanup.
    uwsm finalize
else
    # Unmanaged sessions need their display and application environment imported.
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE I3SOCK
    variables=()
    for name in PATH DISPLAY WAYLAND_DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE I3SOCK \
        XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_DATA_DIRS \
        XRESOURCES XCURSOR_THEME XCURSOR_SIZE QT_QPA_PLATFORM \
        QT_WAYLAND_DISABLE_WINDOWDECORATION GDK_BACKEND SDL_VIDEODRIVER \
        CLUTTER_BACKEND _JAVA_AWT_WM_NONREPARENTING; do
        if [[ -v $name ]]; then
            variables+=("$name")
        fi
    done
    dbus-update-activation-environment --systemd "${variables[@]}"
fi

if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    target=wayland.target
else
    target=xorg.target
fi
exec systemctl --user start "$target"
