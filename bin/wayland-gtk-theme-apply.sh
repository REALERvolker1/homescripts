#!/usr/bin/env bash

gtk3_settings=$(cat "$XDG_CONFIG_HOME/gtk-3.0/settings.ini" | sed 's/$/\\n/g')
cursor_theme="$(cat /usr/share/icons/default/index.theme | grep '^Inherit' | cut -d '=' -f 2)"

get_setting() {
    local setting="$1"
    local value=$(echo -e $gtk3_settings | grep " $setting" | cut -d '=' -f 2)
    echo "$value"
}

set_setting() {
    if gsettings set org.gnome.desktop.interface "$1" "$2"; then
        echo "Successfully set '$1' '$2'" || echo "ERROR! Failed to set '$1' '$2'"
    fi
}

gtk_theme=$(get_setting 'gtk-theme-name')
icon_theme=$(get_setting 'gtk-icon-theme-name')

font_name=$(get_setting 'gtk-font-name')
#font_antialias=$(get_setting 'gtk-xft-antialias')
font_hintstyle=$(get_setting 'gtk-xft-hintstyle' | sed 's/^hint//')
#font_rgb=$(get_setting 'gtk-xft-rgba')

set_setting 'gtk-theme' "$gtk_theme"
set_setting 'icon-theme' "$icon_theme"
set_setting 'cursor-theme' "$cursor_theme"
set_setting 'font-name' "$font_name"
#set_setting 'font-antialiasing' "$font_antialias"
set_setting 'font-hinting' "$font_hintstyle"
#set_setting 'font-rgb' "$font_rgb"
