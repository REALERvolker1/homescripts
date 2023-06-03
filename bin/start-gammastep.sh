#!/usr/bin/dash

set -eu

geoclue='/usr/libexec/geoclue-2.0/demos/agent'
gammastep="/usr/bin/gammastep"
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    gammastep_args=" -P -m wayland"
else
    gammastep_args=" -P"
fi

if [ "$(pgrep -fc "$geoclue")" -gt 0 ] || \
    [ "$(pgrep -fc "$gammastep")" -gt 0 ] || \
    [ "$(pgrep -fc "$0")" -gt 0 ]
then
    my_id="$$"
    echo "Already running. Restarting"
    killall -e "$gammastep"
    killall -e "$geoclue"
    echo "my id: $my_id"
    for i in $(pgrep -f "$0"); do
        [ "$i" = "$my_id" ] && continue
        kill "$i" && echo "Killed duplicate process: '$i'"
    done
fi

$geoclue &
echo "${gammastep}${gammastep_args:-}"
dash -c "${gammastep}${gammastep_args:-}" &

wait
