#!/usr/bin/env bash

ICON_DIRECTORIES="/usr/share/icons $HOME/.local/share/icons $HOME/.icons"

function list_cursors () {
    for i in $ICON_DIRECTORIES; do
        find "$i" -type d -name "cursors" 2>/dev/null | grep -o '/[^/]*/cursors' | sed "s/\/cursors$//g; s/^\///g"
    done
}
# | grep -o '/[^/]*$'
FORMATS=""
function headfmt () {
    FORMATS="$FORMATS:$2"
    printf "\e[0m\e[1m[\e[9${1}m${2}\e[0m\e[1m]\e[0m\t"
}

function fs_default () {
    if [ -f "$1" ]; then
        headfmt "$2" "$3"
        cat "$1" | grep '^Inherits=' | cut -d '=' -f 2
    fi
}

function get_cursor_theme () {
    printf "\n\e[1m=== CURRENT THEME SETTINGS ===\e[0m\n\n"

    fs_default "/usr/share/icons/default/index.theme" 1 "Default"
    fs_default "$HOME/.icons/default/index.theme" 6 "User Home Default"
    fs_default "$HOME/.local/share/icons/default/index.theme" 6 "User Local Default"

    [ -n "$XCURSOR_THEME" ] && headfmt 2 "env" && echo "$XCURSOR_THEME"

    local flatpak_cursor=$(flatpak override --show | grep 'XCURSOR_THEME' | cut -d '=' -f 2)
    [ -n "$flatpak_cursor" ] && headfmt 4 "Flatpak" && echo "$flatpak_cursor"

    local gsettings_cursor=$(gsettings get org.gnome.desktop.interface cursor-theme)
    [ -n "$gsettings_cursor" ] && headfmt 5 "gsettings" && echo "$gsettings_cursor" | sed "s/'//g"

    local gtk3_cursor=$(cat ~/.config/gtk-3.0/settings.ini | grep '^gtk-cursor-theme-name' | cut -d '=' -f 2)
    [ -n "$gtk3_cursor" ] && headfmt 3 "GTK-3.0" && echo $gtk3_cursor
    local gtk4_cursor=$(cat ~/.config/gtk-4.0/settings.ini | grep '^gtk-cursor-theme-name' | cut -d '=' -f 2)
    [ -n "$gtk4_cursor" ] && headfmt 3 "GTK-4.0" && echo $gtk4_cursor

    local xresource_cursor=$(xrdb get "Xcursor.theme" 2>/dev/null)
    [ -n "$xresource_cursor" ] && headfmt 6 "XRDB" && echo "$xresource_cursor"
}


function set_cursor_theme () {
    local cursortheme="$1"
    if [ -n $cursortheme ] && list_cursors | grep -q "^$cursortheme$"; then
        get_cursor_theme
        printf "\nsetting cursor theme to \e[1m'$cursortheme'\e[0m\n"
        for format in $(echo $FORMATS | tr ':' ' '); do
            case $format in
                "Default")
                    echo "Requires SUDO permission to modify /usr/share/icons/default/index.theme"
                    local theme_str=$(cat /usr/share/icons/default/index.theme | grep '^Inherits=' | cut -d '=' -f 2)
                    sudo sed -i "s/$theme_str/$cursortheme/g" "/usr/share/icons/default/index.theme"
                ;; "Flatpak")
                    echo "Overriding user flatpak settings"
                    flatpak override -u --env=XCURSOR_THEME=$cursortheme
                ;; "env")
                    echo "Export 'XCURSOR_THEME' to be '$cursortheme' in your '.bash_profile'"
                ;; "gsettings")
                    echo "Overriding gsettings cursor. You may have to re-run this command on startup"
                    gsettings set org.gnome.desktop.interface cursor-theme "$cursortheme"
                ;; *)
                    echo "Method $format to be added..."
                ;;
            esac
        done
    else
        headfmt 1 "ERROR" && echo "Must have a cursor theme to set to, '$1' is invalid"
    fi
}


case $1 in
    "-s")
        set_cursor_theme "$2"
        echo
    ;; "-g")
        get_cursor_theme
    ;; "-l")
        list_cursors
    ;; *)
        echo "-s to set, -g to get, -l to list"
    ;;
esac



