#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

declare -A config

config[title]="Nerd Fonts Selector v3 by vlk"
config[favorites]='md 󰀄
pl 
ple '
config[icon_color]="${ROFI_ICON_NORMAL:-#FFFFFF}"
config[icon_font]="Symbols Nerd Font"
config[icon_url]='https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json'
config[icon_file]="${XDG_CACHE_HOME:-$HOME/.cache}/nerd-rofi-glyphnames.json"

config[copy_icon]='edit-copy-symbolic'
config[insert_icon]='input-keyboard-symbolic'
config[stderr]=0

case "${1:-}" in
--stderr)
    config[stderr]=1
    ;;
*)
    echo "${0##*/} [--stderr] to print to stderr, otherwise no args"
    ;;
esac

if [ ! -f "${config[icon_file]}" ] || [[ "$*" == *'--update'* ]]; then
    echo "No icon file found. Downloading icons..."
    curl -SL -o "${config[icon_file]}" "${config[icon_url]}"
fi

function rofize_iconlist() {
    local iconlist="${1:?Error, please pass an iconlist!}"
    local IFS=$'\n\t '
    if ((${config[stderr]})); then
        echo "$iconlist" | while read -r line; do
            printf "%s %s\n" $line >&2
        done
    fi
    echo "$iconlist" | while read -r line; do
        printf "%s\0icon\x1f<span color='${config[icon_color]}' font='${config[icon_font]}'>%s</span>\n" $line
    done

    local IFS=$'\n\t'
}

#version_number="$(jq -r '.METADATA.version' "${config[icon_file]}")"
favorites_or="$(
    favorite_lines="$(cut -d ' ' -f 1 <<<"${config[favorites]}")"
    echo "^(${favorite_lines//
/|})"
)" # (fav1|fav2|fav3)
icon_list="$(jq -r 'to_entries[] | "\(.key) \(.value.char)"' "${config[icon_file]}" | grep -v '^METADATA')"
icon_families="$(
    echo "ALL 󰒆"
    fams="$(awk -F'[- ]' '!seen[$1]++' <<<"$icon_list" | grep -Ev "$favorites_or")"
    echo "${config[favorites]}"
    awk '{ split($1, parts, /-/); printf "%s %s\n", parts[1], $2 }' <<<"$fams"
)"

selected_family="$(rofize_iconlist "$icon_families" | rofi -mesg "${config[title]}" -dmenu)"

if [[ "$selected_family" == 'ALL' ]]; then
    family_list="$icon_list"
else
    family_list="$(grep "^$selected_family-" <<<"$icon_list")"
fi
selected_icon="$(rofize_iconlist "$family_list" | rofi -mesg "$selected_family icons" -dmenu)"
selected_icon_char="$(grep -oP "^$selected_icon \K[^ ]*$" <<<"$family_list")"
echo "$selected_icon_char"

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    action_mesg="Choose an action -- Wayland"
    copycmd='wl-copy'
    insertcmd='wtype'
else
    action_mesg="Choose an action -- Xorg"
    copycmd='xclip'
    insertcmd='xdotool'
fi
if command -v "$copycmd" &>/dev/null; then
    copystr="Copy '$selected_icon_char' to clipboard"
else
    action_mesg="$action_mesg
Missing copy dependency $copycmd"
    copystr=""
fi
if command -v "$insertcmd" &>/dev/null; then
    insertstr="Insert '$selected_icon_char' into textprompt"
else
    action_mesg="$action_mesg
Missing insert dependency $insertcmd"
    insertstr=""
fi

selected_action="$(
    (
        [ -n "${copystr:-}" ] && printf "%s\0icon\x1f%s\n" "$copystr" "${config[copy_icon]}"
        [ -n "${insertstr:-}" ] && printf "%s\0icon\x1f%s\n" "$insertstr" "${config[insert_icon]}"
    ) | rofi -mesg "$action_mesg" -dmenu
)"
case "$selected_action" in
'Copy'*)
    (
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            wl-copy -n "$selected_icon_char"
        else
            echo -n "$selected_icon_char" | xclip -selection clipboard
        fi
    ) && echo "Copied '$selected_icon_char' to the clipboard"
    ;;

'Insert'*)
    (
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            wtype "$selected_icon_char"
        else
            xdotool type "$selected_icon_char"
        fi
    ) && echo "Input '$selected_icon_char'"
    ;;

*)
    echo "$selected_action"
    ;;

esac

echo "Have a nice day!~"
