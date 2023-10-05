#!/usr/bin/dash
[ "$(pgrep "${0##*/}" | wc -l)" -gt 2 ] || while true; do
    nvidia-smi >/dev/null
    sleep 5
done

# [ "$(pgrep "${0##*/}" | wc -l)" -gt 2 ] && exit
# _instance_detect() {
#     local pidfile="${XDG_RUNTIME_DIR:-/tmp}/${0##*/}.pid"
#     if [ -e "$pidfile" ] && pgrep -F "$pidfile" >&2; then
#         echo "Error, ${0##*/} already seems to be running!" >&2
#         exit 2
#     else
#         printf '%s\n' "$$" >"$pidfile"
#     fi
# }

# _getmon() {
#     if [ "$(cat /sys/class/power_supply/ACAD/online)" -eq 1 ]; then
#         echo 999
#     elif [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
#         hyprctl monitors | grep -c '^Monitor'
#     else
#         xrandr | grep -c ' connected'
#     fi
# }

# _instance_detect
# if [ "$(_getmon)" -gt 1 ]; then
#     echo 'blocking GPU sleep'
#     while true; do
#         nvidia-smi >/dev/null
#         sleep 5
#     done
# fi
