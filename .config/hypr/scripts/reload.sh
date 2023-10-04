#!/usr/bin/dash

if [ "$XDG_CURRENT_DESKTOP" = 'Hyprland' ]; then
    hyprctl reload
    hyprctl dispatch forcerendererreload

    pgrep 'waybar' | while read -r line; do
        kill "$line"
    done
    waybar &
    #vlkbg.sh
    #killall -SIGUSR2 waybar

    #notify-send -a "$XDG_CURRENT_DESKTOP" 'reload' 'manually reloaded configuration'
else
    echo "Error, \$XDG_CURRENT_DESKTOP must be set to 'Hyprland'"
    notify-send "Error, \$XDG_CURRENT_DESKTOP must be set to 'Hyprland'"
    exit 1
fi
