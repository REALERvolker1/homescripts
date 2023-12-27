#!/usr/bin/bash
set -eu
IFS=$'\n\t'

_log() {
    printf "[${0##*/}]\t%s\n" "$@" | tee -a "$AUTOSTART_LOG"
}
_panic() {
    _log '[PANIC]' "$@"
    exit 1
}

_add_notice() {
    # noticefile is annoying and in your home directory
    printf '%s\n' "$@" >>"$HOME/.notices"
}

_chkcmd() {
    local -i retval
    local -i tmp_retval
    local -i log=1
    if [[ ${1:-} == '--nolog' ]]; then
        log=0
        shift 1
    fi
    for i in "$@"; do
        command -v "${i:-}" &>/dev/null
        tmp_retval=$?
        ((tmp_retval)) && retval=1
    done
    ((retval)) && ((log)) && _log "Failed to find command(s): ${*:-}"
    return $retval
}

_chkrun() {
    local -i retval
    local -i tmp_retval
    local -i log=1
    if [[ ${1:-} == '--nolog' ]]; then
        log=0
        shift 1
    fi
    for i in "$@"; do
        pgrep -f "${i:-}" &>/dev/null
        tmp_retval=$?
        ((tmp_retval)) || retval=1
    done
    ((retval)) && ((log)) && _log "running command(s): ${*:-}"
    return $retval
}

_chkexec() {
    # if [[ ${1:-} == '--chkcmd' ]]; then
    #     shift 1
    #     _chkcmd "${1:-}" || return 1
    # fi
    _chkcmd "${1:-}" || return 1
    _log "Starting $*"
    ((DRY)) || "$@"
}

_kill() {
    if chkrun "${1:-}"; then
        ((DRY)) || pkill -ef "${1:-}"
    fi
}

_nearest_file() {
    local i retfile
    for i in "$@"; do
        if [[ -r "${i:-}" ]]; then
            retfile="$i"
            break
        fi
    done
    if ((${#retfile})); then
        echo "$retfile"
        return 0
    else
        return 1
    fi
}

declare -a vardeps=()
for i in XDG_RUNTIME_DIR XDG_SESSION_ID; do
    [[ -z ${i:-} ]] && vardeps+=("$i")
done
((${#vardeps[@]})) && _panic "Critical error: undefined variables" "${vardeps[@]}"
unset vardeps

# ensure XDG variables
: "${XDG_CONFIG_HOME:=$HOME/.config}" "${XDG_DATA_HOME:=$HOME/.local/share}" "${XDG_CACHE_HOME:=$HOME/.cache}" "${XDG_STATE_HOME:=$HOME/.local/state}"

# turn these into easily query-able integer "booleans"
declare -i isWayland
declare -i isX
declare -i isTTY

declare -i isHyprland
declare -i isSway
declare -i isWaylandGeneric
declare -i isI3
declare -i isXGeneric
if ((${#WAYLAND_DISPLAY})); then
    isWayland=1
    if ((${#HYPRLAND_INSTANCE_SIGNATURE})); then
        isHyprland=1
    elif ((${#SWAYSOCK})); then
        isSway=1
    else
        isWaylandGeneric=1
    fi
elif ((${#DISPLAY})); then
    isX=1
    if ((${#I3SOCK})); then
        isI3=1
    else
        isXGeneric=1
    fi
elif [[ ${TTY:=$(tty)} == /dev/tty* || ${TERM:-} == 'linux' ]]; then
    isTTY=1
else
    _panic "Could not detect session type!"
fi

[[ -z ${AUTOSTART_LOG:-} ]] && AUTOSTART_LOG="$XDG_RUNTIME_DIR/autostart.${XDG_SESSION_ID:-NULL}.log"

declare -i DRY=0
declare -i SAFE=1
for i in "$@"; do
    case "${i:-}" in
    '--dry')
        DRY=1
        AUTOSTART_LOG="$PWD/${0##*/}.log"
        : >"$AUTOSTART_LOG"
        ;;
    '--unsafe') SAFE=0 ;;
    *) echo "${0##*/} [--dry | --unsafe]" && exit 1 ;;
    esac
done

# procs="$(ps -eo pid,comm,args)"

_log "Begin logging to $AUTOSTART_LOG at {$(date +'%D @ %r')} under ${USER:=$(whoami)}"

# Don't do anything drastic if there are multiple active sessions
if _chkcmd loginctl; then
    sessioncount="$(loginctl list-sessions --no-pager --no-legend | wc -l)"
    if ((sessioncount > 1)); then
        _log "More than 1 session found. Entering UNSAFE mode"
        SAFE=0
    fi
    unset sessioncount
fi

((SAFE)) || _add_notice "Currently in UNSAFE MODE"

start_remove_junk_files() {
    local -a remove_files=(
        "$HOME/.yarnrc"
        "$HOME/.wget-hsts"
        "$HOME/.xsel.log"
        "$HOME/.nv"
    )
    if ((SAFE)); then
        if ((isWayland)); then
            remove_files+=("$HOME/.xsession-errors" "$HOME/.Xauthority")
        fi
    fi
    _chkexec rm -rf "${remove_files[@]}"
}

start_dbus_systemd_environment() {
    ((isTTY)) && return
    _chkexec systemctl --user import-environment DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    _chkexec dbus-update-activation-environment --systemd --all
}

start_xwayland_xhost() {
    ((isWayland && ${#DISPLAY})) && _chkexec xhost +local:
}

start_xorg_xresources() {
    ((isX)) || return
    local xresfile
    xresfile="$(
        _nearest_file "$XRESOURCES" \
            "$XDG_CONFIG_HOME/X11/Xresources" \
            "$XDG_CONFIG_HOME/X11/xresources" \
            "$XDG_CONFIG_HOME/Xresources" \
            "$XDG_CONFIG_HOME/xresources" \
            "$HOME/.Xresources" \
            "$HOME/.xresources"
    )"
    local -i err=$?
    if ((err)); then
        _log "Invalid X resources file: '${xresfile:-}'"
    else
        _chkexec xrdb -merge "$xresfile"
    fi

}

start_nvidia_settings() {
    if ((isX)) && _chkrun nvidia-settings; then
        local config
        config="$(
            _nearest_file "$XDG_CONFIG_HOME/nvidia/settings" \
                "$XDG_CONFIG_HOME/nvidia-settings" \
                "$HOME/.nvidia-settings-rc"
        )"
        local -i err=$?
        if ((err)); then
            _log "Invalid Nvidia settings file: '${config:-}'"
        else
            _chkexec nvidia-settings --config="$config"
        fi
    fi
}

start_polkit_agent() {
    ((isTTY)) && return
    local i plkt
    for i in \
        '/usr/libexec/xfce-polkit' \
        '/usr/lib/xfce-polkit/xfce-polkit' \
        '/usr/libexec/polkit-mate-authentication-agent-1' \
        '/usr/lib/mate-polkit/polkit-mate-authentication-agent-1' \
        '/usr/libexec/polkit-gnome-authentication-agent-1' \
        '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' \
        '/usr/libexec/lxqt-policykit-agent' \
        '/bin/lxpolkit'; do
        if [[ -x $i ]]; then
            plkt="$i"
            break
        fi
    done
    if [[ -z ${plkt:=} ]]; then
        _log "Failed to find a polkit agent!"
        _add_notice "No policykit agent was found"
    elif _chkrun "${plkt}"; then
        _chkexec $plkt
    fi
}

start_gnome_keyring() {
    ((SAFE && isTTY == 0)) || return
    if _chkcmd gnome-keyring-daemon; then
        _chkexec gnome-keyring-daemon -r
    else
        _add_notice "Gnome Keyting Daemon is not running"
    fi
}

start_clipboard() {
    ((isTTY)) && return
    local -a clipcmd
    if ((isWayland)); then
        if _chkcmd wl-clip-persist; then
            clipcmd=(wl-clip-persist --clipboard both)
        else
            for i in /bin/clipmon /usr/lib{,exec}/clipmon; do
                if [[ -x $i ]]; then
                    clipcmd=("$i")
                    break
                fi
            done
            if ((${#clipcmd[@]})); then
                true
            elif _chkcmd wl-copy clipman; then
                local clipmanpath="$XDG_RUNTIME_DIR/clipman-${XDG_SESSION_ID:=999}.hsts"
                [[ -e $clipmanpath ]] && rm -f "$clipmanpath"
                # _kill 'wl-paste'
                clipcmd=(wl-paste -t text --watch clipman store --histpath="$clipmanpath")
            fi
        fi
    else
        if _chkcmd 'xfce4-clipman'; then
            _kill 'xfce4-clipman'
            clipcmd=('xfce4-clipman')
        fi
    fi
    if ((${#clipcmd[@]})); then
        _chkexec "${clipcmd[@]}"
    else
        _add_notice "No suitable clipboard persistence daemon was found"
    fi
}

start_ydotoold() {
    _chkcmd ydotoold || return
    # return if I don't have perms
    if [[ -G /dev/uinput || -O /dev/uinput ]] || id "$USER" | grep -q '[0-9]\+(input)'; then
        _chkrun ydotoold && _chkexec ydotoold
    else
        _add_notice "ydotoold is not running"
    fi
}

start_asusctl_battery_limit() {
    _chkcmd asusctl && _chkexec asusctl -c 80
}

start_gammastep() {
    ((isTTY)) && return
    if ((SAFE)) && _chkcmd gammastep; then
        local mode
        _kill gammastep
        if ((isWayland)); then
            mode=wayland
        elif ((isX)); then
            mode=randr
        fi
        _chkexec gammastep -P -m "$mode"
    else
        _add_notice "Gammastep is not running"
    fi
}

start_dunst() {
    ((isTTY)) || _chkexec dunst
}

start_wallpaper() {
    if ((isTTY || isSway)); then
        return
    elif ((isHyprland)); then
        _chkexec hyprpaper
    else
        _chkexec vlkbg.sh
    fi
}

start_xsettingsd() {
    ((isX)) || return
    _kill xsettingsd
    _chkexec xsettingsd
}

start_steam_symlink_unfucker() {
    ((isTTY || isSway)) && return # sway is my ultra battery saver thing
    [[ ! -d "$HOME/.var/app/com.valvesoftware.Steam" ]] &&
        _chkexec flatpak list --app --columns=application | grep -q 'com.valvesoftware.Steam' &&
        _chkexec mkdir -p "$HOME/.var/app/com.valvesoftware.Steam/.config"

    _chkexec steam-symlink-unfucker.sh
}

start_idle_daemon() {
    ((isTTY)) && return
    local locker
    local -a idlecmd
    _chkcmd vlklock.sh && locker='vlklock.sh'
    if ((isWayland)) && _chkcmd swayidle; then
        return
        # I don't have this set up yet
        #idlecmd=(swayidle)
    elif ((isX)) && _chkcmd xss-lock; then
        idlecmd=('xss-lock' -l "$locker")
        _chkexec xset -dpms
    fi
    _chkexec "${idlecmd[@]}"
}

start_pmgmt() {
    # It's a really resilient program
    _chkexec pmgmt.sh --monitor
}

start_pointer_monitor() {
    ((SAFE && isTTY == 0)) || return
    # It's very finicky but it still has its own dupe detection
    _chkexec pointer.sh -um
}

start_barcmd() {
    if ((isWayland)); then
        __chkexec waybar
    fi
}

start_networkmanager_applet() {
    ((isTTY)) && return
    _chkexec nm-applet
}

start_cursor_theme() {
    ((isTTY)) && return
    _chkexec set-cursor-theme.sh --session
}

start_xorg_keyboard_settings() {
    ((isX)) || return
    _chkexec numlockx
    _chkexec xmodmap -e "clear lock"
    _chkexec xmodmap -e "keycode 66 = Escape NoSymbol Escape"
}

start_flameshot_background() {
    ((isX)) && _chkexec flameshot
}

start_picom() {
    ((isX)) || return
    _chkexec picom
    _chkexec flashfocus
}

start_autotiling() {
    ((isI3 || isSway)) || return
    _chkexec autotiling-rs
}

start_scratchpad_terminal() {
    if ((isHyprland)) && _chkcmd hdrop; then
        return
    elif ((isI3)) && _chkcmd kitti3; then
        return
    elif ((isI3 || isSway || isHyprland)); then
        _chkexec scratchpad_terminal.sh
    fi
}

# Execute
set +eu
wait
