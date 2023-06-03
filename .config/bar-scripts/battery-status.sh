#!/usr/bin/bash

BATPATH='/sys/class/power_supply/BAT1'
ACPATH='/sys/class/power_supply/ACAD'
BATUPOWER='/org/freedesktop/UPower/devices/battery_BAT1'

MODE="$1"

if [ "$MODE" = '--wattage' ]; then
    upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -oP 'energy-rate: *\K.*$' | grep -o '^.*\...'
    #echo "scale=2; $(cat "$BATPATH/voltage_now") * $(cat "$BATPATH/current_now") / 1000000000000" | bc
    #gdbus monitor -y -d 'org.freedesktop.UPower' --object-path '/org/freedesktop/UPower/devices/battery_BAT1' | grep --line-buffered -oP "'EnergyRate':\s*<\K[0-9.]+" | grep -o '^.*\...'
    exit 0
elif [ "$MODE" = '--wattage-monitor' ]; then
    upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -oP 'energy-rate: *\K.*$' | grep -o '^.*\...'
    gdbus monitor -y -d 'org.freedesktop.UPower' --object-path '/org/freedesktop/UPower/devices/battery_BAT1' | grep --line-buffered -oP "'EnergyRate':\s*<\K[0-9.]+" | grep -o '^.*\...'
fi

print_fmt () {
    local online
    [ "$2" -eq 1 ] && online=true || online=false
    case "$MODE" in
        '--json')
            echo "{\"percent\": \"$1\", \"online\": \"$online\", \"power\": \"$3\"}"
        ;; *)
            echo "${1}% ${3}W AC: $online"
        ;;
    esac
}

percent_cache="$(cat "$BATPATH/capacity")"
stat_cache="$(cat "$ACPATH/online")"
watt_cache="$(echo "scale=2; $(cat "$BATPATH/voltage_now") * $(cat "$BATPATH/current_now") / 1000000000000" | bc)"

print_fmt "$percent_cache" "$stat_cache" "$watt_cache"

gdbus monitor -y \
    -d 'org.freedesktop.UPower' \
    --object-path "$BATUPOWER" |\
while read -r line; do
    current_percent="$(echo "$line" | grep -oP "'Percentage':\s*<\K[0-9.]+")"
    current_stat="$(echo "$line" | grep "'IconName'" &>/dev/null && cat "$ACPATH/online")"
    current_watt="$(echo "$line" | grep -oP "'EnergyRate':\s*<\K[0-9.]+" | grep -o '^.*\...')"

    [ -z "$current_percent" ] && [ -z "$current_stat" ] && [ -z "$current_watt" ] && continue

    [ -n "$current_percent" ] && percent_cache="$current_percent"
    [ -n "$current_stat" ] && stat_cache="$current_stat"
    [ -n "$current_watt" ] && watt_cache="$current_watt"

    print_fmt "$percent_cache" "$stat_cache" "$watt_cache"

done
