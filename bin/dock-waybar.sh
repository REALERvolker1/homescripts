#!/usr/bin/dash

for i in $(pgrep "$0"); do
    kill "$i"
done

config_path="$XDG_CONFIG_HOME/waybar/dock-config.jsonc"
if [ -f "$config_path" ]; then
    waybar --config "$config_path"
else
    echo "Error, waybar dock config '$config_path' does not exist!"
fi
