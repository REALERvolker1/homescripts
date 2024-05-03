#!/usr/bin/bash
set -u

ME="${0##*/}"

_log() {
    printf "[$ME] %s\n" "$@"
    printf '%s\n' "$@" >>"$LOG_FILE"
}

# kill me now
_panic() {
    _log "$@"
    exit 1
}
# Check if a command exists in the system path.
_cmd() {
    command -v "$1" &>/dev/null
}
# Check if the program binary is running, if not, then run it.
_pgrepx() {
    pgrep -f "$1" &>/dev/null || "$@"
}

# set up sane logging
LOG_FILE="$XDG_CACHE_HOME/$ME.log"
mkdir -p "$XDG_CACHE_HOME"

# This is only meant for graphical environments
[[ -z ${WAYLAND_DISPLAY-} && -z ${DISPLAY-} ]] && _panic "Error, must be run in a graphical session!"

LOCKFILE="$XDG_RUNTIME_DIR/$ME-$XDG_SESSION_ID.lock"

# make sure this is the only instance of autostart running in this session
[[ -f $LOCKFILE ]] && _panic "Error, lockfile exists: $LOCKFILE"

# now I can make 100% sure the files exist
: >"$LOG_FILE"
: >"$LOCKFILE"

# autostarts

# This overwrites some env vars in my systemd user session, but idc because it makes stuff just work
systemctl --user import-environment DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
dbus-update-activation-environment --systemd --all

# Pretty sure this detects if it is started properly, and I don't want to mess with it
gnome-keyring-daemon --start --components=secrets &

(
    pk=''
    for i in \
        '/usr/lib/mate-polkit/polkit-mate-authentication-agent-1' \
        '/usr/libexec/xfce-polkit' \
        '/usr/lib/xfce-polkit/xfce-polkit' \
        '/usr/libexec/polkit-mate-authentication-agent-1' \
        '/usr/libexec/polkit-gnome-authentication-agent-1' \
        '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' \
        '/usr/libexec/lxqt-policykit-agent' \
        'lxpolkit'; do
        if [[ -x $i ]]; then
            pk="$i"
            break
        fi
    done

    if [[ -n $pk ]]; then
        "$pk"
    else
        echo "No suitable polkit agent found"
    fi
    unset pk
) &

# _pgrepx ydotoold &

# dunst can take care of its own duplicates
dunst &

set-cursor-theme.sh --session &
# _pgrepx steam-symlink-unfucker.sh &
# _pgrepx heroic-symlink-unfucker.sh &
_pgrepx symlink_unfuckd &

_pgrepx nm-applet &

pmgmt.sh --monitor &

# wayland-specific stuff
if [[ -n ${WAYLAND_DISPLAY-} ]]; then
    (
        for i in "$HOME/.xsession-errors" "$HOME/.Xauthority"; do
            [[ -f $i ]] && rm "$i"
        done
    ) &

    _pgrepx gammastep -P -m wayland &
    xhost +local: &
    # xhost +local:root:

    # I'm pretty sure this works on other compositors too
    hyprpaper &
    wl-clip-persist --clipboard regular

    _pgrepx waybar &
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE-} ]]; then
        _pgrepx hyprpointer status-monitor &
        hyprpm reload &

    fi

elif [[ -n ${DISPLAY-} ]]; then
    [[ -r "${XRESOURCES-}" ]] && xrdb -merge "${XRESOURCES-}" &

    _pgrepx gammastep -P -m randr &

    [[ -f "$XDG_CONFIG_HOME/nvidia/settings" ]] && nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" &

    (
        pkill -ef 'xfce4-clipman'
        xfce4-clipman
    ) &

    _pgrepx xsettingsd &
    xset -dpms &
    numlockx &

    _pgrepx xss-lock -l "vlklock.sh" &

    #(
    #    mo="$(xinput | grep -oP '↳ Glorious Model O\s+id=\K[0-9]+')"
    #    ret="$?"
    #    ((ret)) || xinput set-prop "$mo" 'libinput Accel Profile Enabled' 0 1 0
    #) &
    (
        xmodmap -e "clear lock"
        xmodmap -e "keycode 66 = Escape NoSymbol Escape"
    ) &

    #flameshot &

    vlkbg.zsh &

    if [[ -n "${I3SOCK-}" ]]; then
        _pgrepx autotiling-rs &
        _pgrepx picom &
    fi

    vlk-xrandr.sh &
fi

wait
