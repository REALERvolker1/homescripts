#!/usr/bin/dash

__panic() {
    echo "Error, $*"
    notify-send -a "${0##*/}" "Error" "$*" &
}
chkcmd() {
    command -v "$1" >/dev/null 2>&1
}
__cexec() {
    if [ "${1:=}" = '--safe' ]; then # we've already checked it
        shift 1
        exec "$@"
    elif chkcmd "$1"; then
        exec "$@"
    else
        __panic "Error, command '$1' not found!"
    fi
}

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    # wl-clip-persist clipboard primary/both makes text nonselectable in gtk applications
    # https://github.com/Linus789/wl-clip-persist/issues/3
    if chkcmd wl-clip-persist; then
        __cexec --safe 'wl-clip-persist' --clipboard regular
    else
        pkill -ef clipmon
        for i in clipmon /usr/lib/clipmon /usr/libexec/clipmon; do
            chkcmd "$i" || continue
            __cexec --safe "$i"
            break
        done
        #fallback to clipman -- with separate histfile per XDG session for security
        clipmanpath="$XDG_RUNTIME_DIR/clipman-${XDG_SESSION_ID:=999}.hsts"
        [ -f "$clipmanpath" ] && rm -f "$clipmanpath"
        pkill -ef wl-paste
        __cexec wl-paste -t text --watch clipman store --histpath="$clipmanpath"
    fi
    #__cexec wl-paste -t text --watch cliphist store --histpath="$XDG_RUNTIME_DIR/clipman.hsts"
elif [ -n "${DISPLAY:-}" ]; then
    ## remnant of my half-baked clipboard manager that "worked" until I had to copy folders in nemo/thunar or images
    # monitor_path="$XDG_CONFIG_HOME/shell/rustcfg/clipboard-monitor"
    # monitor_bin="$monitor_path/target/release/clipboard-monitor"
    # if [ -d "$monitor_path" ]; then
    #     if [ -x "$monitor_bin" ]; then
    #         exec "$monitor_bin"
    #     else
    #         if command -v cargo; then
    #             cd "$monitor_path"
    #             cargo build --release
    #             exec "$monitor_bin"
    #         fi
    #     fi
    # fi
    pkill -ef 'xfce4-clipman'
    __cexec --safe 'xfce4-clipman'
fi
