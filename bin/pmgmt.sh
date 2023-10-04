#!/usr/bin/bash
# script by vlk

set -u

# AC device paths
UPOWER_AC_DEVICE='/org/freedesktop/UPower/devices/line_power_ACAD'
SYSFS_AC_DEVICE='/sys/class/power_supply/ACAD/online'

KEYBOARD_PATH='sysfs/leds/asus::kbd_backlight'

# configuration
bat_kbd=1
bat_backlight=40
bat_powerprof='balanced'

ac_kbd=3
ac_backlight=80
ac_powerprof='performance'

ac_command_center() {
    pgrep 'gpublock.sh' >/dev/null && killall 'gpublock.sh'
    local ac_state="${1:-}"
    echo "$ac_state" >&2
    if [ "$ac_state" = 'true' ]; then
        light -Srs "$KEYBOARD_PATH" "$ac_kbd"
        light -S "$ac_backlight"
        powerprofilesctl set "$ac_powerprof"
        asusctl bios -O "true"
        # zsh -c "gpublock.sh &!"
        gpublock.sh &
        disown

    elif [ "$ac_state" = 'false' ]; then
        light -Srs "$KEYBOARD_PATH" "$bat_kbd"
        light -S "$bat_backlight"
        powerprofilesctl set "$bat_powerprof"
        asusctl bios -O "false"
    fi
}

_instance_detect() {
    local pidfile="${XDG_RUNTIME_DIR:-/tmp}/${0##*/}.pid"
    if [ -e "$pidfile" ] && pgrep -F "$pidfile" >&2; then
        echo "Error, ${0##*/} already seems to be running!" >&2
        exit 2
    else
        printf '%s\n' "$$" >"$pidfile"
    fi
}

sysfs_detect() {
    case "$(cat "$SYSFS_AC_DEVICE")" in
    1)
        ac_command_center 'true'
        ;;
    0)
        ac_command_center 'false'
        ;;
    *)
        echo "ERROR: Failed to get current AC state"
        exit 1
        ;;
    esac
}

ac_monitor() {
    echo "Monitoring $UPOWER_AC_DEVICE" >&2
    dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='$UPOWER_AC_DEVICE',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" |& grep --line-buffered -oP 'boolean \K.*$' | while read -r line; do
        ac_command_center "$line"
    done
}

_instance_detect
ac_monitor
