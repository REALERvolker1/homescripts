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
    #__cexec 'wl-clip-persist' --clipboard both
    [ -f "$XDG_RUNTIME_DIR/clipman.hsts" ] && rm -f "$XDG_RUNTIME_DIR/clipman.hsts"
    __cexec wl-paste -t text --watch clipman store --histpath="$XDG_RUNTIME_DIR/clipman.hsts"
    #__cexec wl-paste -t text --watch cliphist store --histpath="$XDG_RUNTIME_DIR/clipman.hsts"
elif [ -n "${DISPLAY:-}" ]; then
    monitor_path="$XDG_CONFIG_HOME/shell/rustcfg/clipboard-monitor"
    monitor_bin="$monitor_path/target/release/clipboard-monitor"
    if [ -d "$monitor_path" ]; then
        if [ -x "$monitor_bin" ]; then
            exec "$monitor_bin"
        else
            if command -v cargo; then
                cd "$monitor_path"
                cargo build --release
                exec "$monitor_bin"
            fi
        fi
    fi
    pgrep 'xfce4-clipman' >/dev/null || __cexec 'xfce4-clipman'
fi
