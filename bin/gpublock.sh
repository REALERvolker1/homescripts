#!/usr/bin/dash

[ "$(pgrep "${0##*/}" | wc -l)" -gt 2 ] && exit

echo 'blocking GPU sleep'
# [ "$(xrandr | grep -c ' connected')" -gt 1 ] || 

if [ "$(hyprctl monitors | grep -c '^Monitor')" -gt 1 ]; then
    while true; do
        nvidia-smi >/dev/null
    done
fi

