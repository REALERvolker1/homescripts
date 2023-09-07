#!/usr/bin/dash

__panic() {
    echo "Error, $*"
    notify-send -a "${0##*/}" "Error" "$*" &
}
__cexec() {
    if command -v "$1" >/dev/null 2>&1; then
        exec "$@"
    else
        __panic "Error, command '$1' not found!"
    fi
}

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    __cexec 'wl-clip-persist' --clipboard both
elif [ -n "${DISPLAY:-}" ]; then
    pgrep 'xfce4-clipman' >/dev/null || __cexec 'xfce4-clipman'
fi
