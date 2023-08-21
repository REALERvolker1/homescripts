#!/usr/bin/dash

[ "$(pgrep "${0##*/}" | wc -l)" -gt 2 ] && exit

echo 'blocking GPU sleep'
# [ "$(xrandr | grep -c ' connected')" -gt 1 ] || 

_getmon () {
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl monitors | grep -c '^Monitor'
    else
        xrandr | grep -c ' connected'
    fi
}

if [ "$(_getmon)" -gt 1 ]; then
    while true; do
        nvidia-smi >/dev/null
        sleep 5
    done
fi

