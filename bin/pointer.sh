#!/usr/bin/dash
# rewrite of my touchpad script to be a bit nicer, work with Waybar better, and use Hyprland 0.30.0 device query
set -eu
IFS="$(printf "\n\t")"
_error() { notify-send -a "${0##*/}" "Error" "$*" && exit 1; }

arg="${1:-}"

icon_on='󰟸'
icon_off='󰤳'
icon_unk='󰟸 ?'

if [ "${USER:=$(whoami)}" = root ]; then
    echo "Running as root, some functions may behave abnormally"
else
    UDEV_FILE="$XDG_RUNTIME_DIR/touchpad-udev-statusfile"
    TOUCHPAD_STATUS="${TOUCHPAD_STATUS:-$XDG_RUNTIME_DIR/touchpad-statusfile}"
    touch -- "$UDEV_FILE" "$TOUCHPAD_STATUS"

    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        notify-send "Deprecated" "Hyprland session is deprecated, please use hyprpointer-rs instead."
        exit 99
        platform='hyprland'
        touchpad_name='asup1205:00-093a:2003-touchpad'
        wireless_name='glorious-model-o-wireless'
        wired_name='glorious-model-o'
    elif [ -n "${SWAYSOCK:-}" ]; then
        echo '' >"$TOUCHPAD_STATUS"
        # on sway, this script is not needed. Set the following option in $XDG_CONFIG_HOME/sway/config:
        # input type:touchpad {
        #     events disabled_on_external_mouse
        # }
        exit 0
    elif [ -n "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        platform='x11'
        touchpad_name='ASUP1205:00 093A:2003 Touchpad'
        wireless_name='Glorious Model O Wireless'
        wired_name='Glorious Model O'
    else
        _error "unsupported platform!"
    fi
    egrep_mouse_name="(${wireless_name}|${wired_name})"
fi

has_mouse() {
    case "$platform" in
    x11)
        xinput | grep -qE "↳ ${egrep_mouse_name}[[:space:]]*id"
        ;;
    hyprland)
        hyprctl devices -j | grep -qE "\"name\": \"${egrep_mouse_name}\""
        ;;
    esac
}

query_status() {
    case "$platform" in
    x11)
        xinput list-props "$touchpad_name" | grep -oP '^[[:space:]]*Device Enabled \(.*:[[:space:]]*\K[0-9]*'
        ;;

    hyprland)
        hyprctl getoption device:"$touchpad_name":enabled | grep -oP 'int: \K[0-9]*'
        ;;
    esac
}

status_print() {
    case "$1" in
    1) status="$icon_on" ;;
    0) status="$icon_off" ;;
    *) status="$icon_unk" ;;
    esac
    echo "$status" >"$TOUCHPAD_STATUS"
}

touchpad_operation() {
    status="$1"
    retval="$(
        case "$platform" in
        x11)
            xinput set-prop "$touchpad_name" 'Device Enabled' "$status" >/dev/null || echo false
            ;;
        hyprland)
            #[ "$(hyprctl keyword device:"$touchpad_name":enabled "$status")" = 'ok' ] || echo false
            printf '%s\n' "device:$touchpad_name {" "enabled=$status" "}" >"$XDG_CONFIG_HOME/hypr/pointer.sh.conf" || echo false
            ;;
        esac
    )"
    if ${retval:-true}; then # Have to write it like this or shfmt will get mad at me
        status_print "$status"
    else
        _error "Could not set touchpad status to '$status'"
    fi

}

normalize_operation() {
    if has_mouse; then
        touchpad_operation 0
    else
        touchpad_operation 1
    fi
}

case "$arg" in
-i | --icon)
    cat "$TOUCHPAD_STATUS"
    ;;
-m | --monitor)
    cat "$TOUCHPAD_STATUS"
    inotifywait -qme close_write "$TOUCHPAD_STATUS" | while read -r line; do
        cat "$TOUCHPAD_STATUS"
    done
    ;;
-te | --enable)
    touchpad_operation 1
    ;;
-td | --disable)
    touchpad_operation 0
    ;;
-t | --toggle)
    touchpad_status="$(query_status)"
    case "${touchpad_status:-}" in
    1) touchpad_operation 0 ;;
    0) touchpad_operation 1 ;;
    *) _error "Touchpad status '${touchpad_status:-}' is not properly defined!" ;;
    esac
    ;;
-n | --normalize)
    normalize_operation
    ;;
-um | --udev-monitor)
    normalize_operation
    udevadm monitor --udev --subsystem-match=usb | grep -Eo --line-buffered '(add|remove)' | while read -r line; do
        [ "$(cat "$UDEV_FILE")" = "$line" ] && continue
        (
            sleep 1
            normalize_operation
        ) &
        echo "$line" >"$UDEV_FILE"
        echo "$line"
    done
    ;;
--setup-xorg-system)

    (
        cat <<BRUH
# /etc/udev/rules.d/69-${0##*/}.rules
# Glorous Model O Wireless
SUBSYSTEMS=="usb", ATTRS{idVendor}=="258a", ATTRS{idProduct}=="2011", TAG+="uaccess"
# Glorous Model O Wireless (unplugged)
SUBSYSTEMS=="usb", ATTRS{idVendor}=="258a", ATTRS{idProduct}=="2022", TAG+="uaccess"
BRUH
    ) | tee "/etc/udev/rules.d/69-${0##*/}.rules"

    (
        cat <<BRUH
# /etc/X11/xorg.conf.d/69-${0##*/}.conf
Section "InputClass"
    Identifier "Mouse Fix"
    MatchIsPointer "on"
    Option "AccelProfile" "flat"
    Option "AccelSpeed" "0"
EndSection

Section "InputClass"
    Identifier "Touchpad options"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
EndSection
BRUH
    ) | tee "/etc/X11/xorg.conf.d/69-${0##*/}.conf"
    ;;

-p | --print-location)
    echo "$TOUCHPAD_STATUS"
    ;;
*)
    echo "${0##*/} --arg"
    printf '%s (%s)\t%s\n' \
        '--icon' '-i' 'get statusline icon' \
        '--monitor' '-m' 'monitor icon' \
        '--enable' '-te' 'enable touchpad' \
        '--disable' '-td' 'disable touchpad' \
        '--toggle' '-t' 'toggle touchpad' \
        '--normalize' '-n' 'normalize settings' \
        '--udev-monitor' '-um' 'monitor device remove/add, then normalize' \
        '--print-location' '-p' 'print statusfile location' \
        '--setup-xorg-system' '' 'Set up system config files for xorg xinput'
    exit 1
    ;;
esac
