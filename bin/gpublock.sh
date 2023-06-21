#!/usr/bin/dash

if [ "$(hyprctl monitors | grep -c '^Monitor')" -gt 1 ]; then
    while true; do
        nvidia-smi
        sleep 5
    done
fi

