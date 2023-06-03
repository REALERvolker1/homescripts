#!/usr/bin/dash
# vim:ft=sh
# script by vlk
# depends: xidlehook https://github.com/jD91mZM2/xidlehook
# weak-deps: light
# designed to be run right after switching to battery power or AC power

type="${1}"

program_name="${0##*/}"
program_id="$$"
pids="$(pidof -x "$program_name")"

#"${pids// /$'\n'}" # BASH ONLY
if [ "$(printf '%s\n' "$pids" | tr ' ' '\n' | wc -l)" -gt 1 ]; then
    printf '%s\n' "$pids" | tr ' ' '\n' | grep -v "$program_id" | while read -r line; do
        kill "$line" && printf  "%s is already running. Killed %s\n" "$program_name" "$line"
    done
    #notify-send -r 2999 -a "$program_name" -i 'emblem-error' -u 'normal' "Error executing $program_name" "More than one instance of $program_name detected. Could not kill."
fi

LOCK_COMMAND="${LOCKSCREEN:-vlkexec --lock 1}"

case "$type" in
    'AC')
        printf 'initialized with AC profile\n'
        backlight_timer=600
        backlight_dim=40
        lock_timer=120
        screensaver_timer=900
    ;; 'BAT')
        printf 'initialized with battery profile\n'
        backlight_timer=120
        backlight_dim=20
        lock_timer=120
        screensaver_timer=600
    ;; 'TEST')
        printf 'initialized with testing profile\n'
        backlight_timer=5
        backlight_dim=20
        lock_timer=5
        screensaver_timer=600
    ;; *)
        printf "%s
AC\tAC xidlehook settings
BAT\tBATTERY xidlehook settings" "$0"
        exit 1
    ;;
esac

killall xidlehook
killall xss-lock

xset s "$screensaver_timer"
xss-lock -l "$LOCK_COMMAND" &

xidlehook --not-when-audio --not-when-fullscreen --detect-sleep \
--timer "$backlight_timer" "light -S $backlight_dim" "light -I" \
--timer "$lock_timer" "$LOCK_COMMAND" "light -I" &

wait
