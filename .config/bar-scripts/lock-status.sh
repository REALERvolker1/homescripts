#!/usr/bin/dash

DEVICE='/dev/input/by-path/platform-i8042-serio-0-event-kbd'

# They don't send inotify events :(
NUM_DEVICE="/sys/class/leds/input12::numlock/brightness"
CAP_DEVICE="/sys/class/leds/input12::capslock/brightness"
check_numlock () {
    local output='󰎸'
    local state="$(xset q)"
    #[ "$(cat "$NUM_DEVICE")" = 1 ] && output='󰎶'
    #[ "$(cat "$CAP_DEVICE")" = 1 ] && output="$output 󰘲"
    printf '%s' "$state" | grep -P 'Num Lock: *\Kon' > /dev/null && output='󰎶'
    printf '%s' "$state" | grep -P 'Caps Lock: *\Kon' > /dev/null && output="$output 󰘲"
    printf '%s\n' "$output"
}

check_numlock_but_cooler () {
    #sed 's/1/󰎶/;s/0/󰎸/' "$NUM_DEVICE"
    xset q | grep -Po 'Num Lock: *\Kon' > /dev/null && echo 󰎶 || echo 󰎸
}

#while :; do check_numlock; sleep 1; done

evtest "$DEVICE" | grep --line-buffered -o '(KEY_NUMLOCK)' | while read line; do
    check_numlock_but_cooler
done
