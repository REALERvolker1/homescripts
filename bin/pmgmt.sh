#!/usr/bin/bash
# script by vlk

set -u

# config
UPOWER_AC_DEVICE='/org/freedesktop/UPower/devices/line_power_ACAD'
KEYBOARD_PATH='sysfs/leds/asus::kbd_backlight'
me="${0##*/}"
pidfile="$XDG_RUNTIME_DIR/${me}.pid"
gpublock_arg='--gpu-block'

ac_command_center() {
    kill_gpu_block
    echo "$1"
    if [ "$1" = true ]; then
        light -Srs "$KEYBOARD_PATH" 3
        light -S 80
        powerprofilesctl set performance
        asusctl bios -O true
        "$0" "$gpublock_arg" &
        disown

    elif [ "$1" = false ]; then
        light -Srs "$KEYBOARD_PATH" 1
        light -S 40
        powerprofilesctl set balanced
        asusctl bios -O false
    fi
}

kill_gpu_block() {
    local gpublock
    gpublock="$(ps -eo pid,comm,args | grep -oP "^\s*\K[0-9]*(?=\s*${me}.*${gpublock_arg})" | grep -vE "($$|$(($$ + 1)))")"
    # [ -z "${gpublock:-}" ] && return
    # if kill $gpublock; then
    #     echo "killed gpublock"
    #     return 0
    # else
    #     echo "Error killing gpublock"
    #     return 1
    # fi
    [[ -n ${gpublock:-} ]] && kill $gpublock && echo "killed gpublock"
}

if [[ "${1:-}" = "$gpublock_arg" ]]; then
    kill_gpu_block
    while true; do
        nvidia-smi >/dev/null
        sleep 5
    done
    exit 0
fi

nondeps="$(
    for i in light powerprofilesctl asusctl nvidia-smi acpi; do
        command -v "$i" >/dev/null 2>&1 || echo "$i"
    done
)"
if [[ -n "${nondeps:-}" ]]; then
    notify-send -a "$me" 'Missing dependencies' "$(printf '%s\n' 'failed to find commands:' "${nondeps[@]}" | tee /dev/stderr)"
    exit 1
fi

if [[ -e "$pidfile" ]] && pgrep -F "$pidfile" >&2; then
    echo "Error, $me already seems to be running!" >&2
    exit 2
fi
echo "$$" >"$pidfile"

ac_command_center "$(acpi -a | head -n 1 | sed -E 's/.*: ([^-]+)-.*/\1/g ; s/on/true/ ; s/off/false/')"
echo "Monitoring $UPOWER_AC_DEVICE" >&2
dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='$UPOWER_AC_DEVICE',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" | grep --line-buffered -oP 'boolean \K(true|false)' | while read -r line; do
    ac_command_center "$line"
done
