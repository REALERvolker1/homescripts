#!/usr/bin/dash
# script by vlk

# config
UPOWER_AC_DEVICE='/org/freedesktop/UPower/devices/line_power_ACAD'
SYSFS_AC_DEVICE='/sys/class/power_supply/ACAD/online'
#KEYBOARD_PATH='sysfs/leds/asus::kbd_backlight'
buscmd="busctl call org.freedesktop.UPower /org/freedesktop/UPower/KbdBacklight org.freedesktop.UPower.KbdBacklight SetBrightness i"
me="${0##*/}"
my_pid="$$"
#pidfile="$XDG_RUNTIME_DIR/${me}.pid"
pidfile="/tmp/${me}.pid"

ac_power_profile=performance

ac_command_center() {
    killall nvidia-smi
    echo "$1"
    if [ "$1" = true ]; then
        #light -Srs "$KEYBOARD_PATH" 3
        $buscmd 3 &
        brightnessctl s '100%'
        powerprofilesctl set "$ac_power_profile"
        asusctl bios -O true
        #nvidia-smi dmon -d 5 &>/dev/null &
        if [ "$(supergfxctl -g)" = Hybrid ]; then
            nvidia-smi -l >/dev/null 2>&1 &
        fi

    elif [ "$1" = false ]; then
        #light -Srs "$KEYBOARD_PATH" 1
        $buscmd 1 &
        brightnessctl s '40%'
        powerprofilesctl set balanced
        asusctl bios -O false
    fi
}

auto_check() {
    if [ "$(cat "$SYSFS_AC_DEVICE")" -eq 1 ]; then
        ac_command_center true
    else
        ac_command_center false
    fi
}

pid_check() {
    if [ -e "$pidfile" ] && pgrep -F "$pidfile" >&2; then
        echo "Error, $me already seems to be running!" >&2
        exit 2
    fi
    echo "$my_pid" >"$pidfile"
}

case "${1:-}" in
--ac | -a)
    ac_command_center true
    ;;
--bat | -b)
    ac_command_center false
    ;;
--oneshot | -o)
    auto_check
    ;;
--monitor | -m)
    pid_check
    auto_check
    echo "Monitoring $UPOWER_AC_DEVICE" >&2
    dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='$UPOWER_AC_DEVICE',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" | grep --line-buffered -oP 'boolean \K(true|false)' | while read -r line; do
        ac_command_center "$line"
    done
    exit "${?:-0}"
    ;;
*)
    echo "Invalid argument: $me ${1:-}

Current options:
--ac (-a)         run the commands for the onAC state
--bat (-b)        run the commands for the onBattery state

--oneshot (-o)    auto-detect the correct state and run the commands for that
--monitor (-m)    Monitor the battery state, and automatically set the correct state
"
    exit 1
    ;;
esac
