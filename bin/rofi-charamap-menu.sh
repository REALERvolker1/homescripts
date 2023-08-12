#!/usr/bin/env bash

_iconify () {
    local icon="${1:?Error, must specify an icon!}"
    local type="${2:-}"
    local icon_color='#FFFFFF'

    case "$type" in
        'urgent')
            icon_color="${ROFI_URGENT:-#000000}"
        ;;
        'active')
            icon_color="${ROFI_ACTIVE:-#000000}"
        ;; *)
            icon_color="${ROFI_NORMAL:-$icon_color}"
        ;;
    esac

    printf "<span color='%s'>%s</span>" "$icon_color" "$icon"
}

menu="$(
cat << EOF
Nerd Fonts\0icon\x1f$(_iconify )
Emojis\0icon\x1f$(_iconify 😅)
Special Characters\0icon\x1f$(_iconify ザ)
GTK-3.0 Icons\0icon\x1fgtk3-demo
Gnome Characters\0icon\x1fdesktop-environment-gnome
Character Map\0icon\x1f$(_iconify 󰀫)
EOF
)"
selection="$(echo -e "$menu" | rofi -dmenu -mesg 'vlkexec character map selector')"

case "$selection" in
    'Nerd Fonts')
        exec nerd-rofi.sh
    ;; 'Emojis')
        exec rofimoji
    ;; 'Special Characters')
        exec rofimoji --files all
    ;; 'GTK-3.0 Icons')
        exec gtk-icon-rofi.py
    ;; 'Gnome Characters')
        exec gnome-characters
    ;; 'Character Map')
        exec gucharmap
    ;;
esac
