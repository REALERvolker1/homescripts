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


ac_command_center () {
    local ac_state="${1:-}"
    echo "$ac_state"
    if [ "$ac_state" = 'true' ]; then
        light -Srs "$KEYBOARD_PATH" "$ac_kbd"
        light -S "$ac_backlight"
        powerprofilesctl set "$ac_powerprof"
        asusctl bios -O "true"

    elif [ "$ac_state" = 'false' ]; then
        light -Srs "$KEYBOARD_PATH" "$bat_kbd"
        light -S "$bat_backlight"
        powerprofilesctl set "$bat_powerprof"
        asusctl bios -O "false"
    fi
}

ac_monitor () {
    dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='$UPOWER_AC_DEVICE',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" |& grep --line-buffered -oP 'boolean \K.*$' | while read -r line; do
        ac_command_center "$line"
    done
}

_instance_detect () {
    local program_name="${0##*/}"
    local program_id="$$"
    local pids
    pids="$(pidof -x "$program_name")"

    if [ "$(echo "$pids" | tr ' ' '\n' | wc -l)" -gt 1 ]; then
        for i in $pids; do
            [ "$i" = "$program_id" ] && continue
            kill "$i" && printf "%s is already running. Killed %s\n" "$program_name" "$i"
        done
    fi
}

_instance_detect

case "$(cat "$SYSFS_AC_DEVICE")" in
    1)
        ac_command_center 'true'
    ;; 0)
        ac_command_center 'false'
    ;; *)
        echo "ERROR: Failed to get current AC state"
        exit 1
    ;;
esac

ac_monitor
