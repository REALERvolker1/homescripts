#!/usr/bin/env bash

iconify () {
    printf "<span color='%s'>%s</span>" "${ROFI_ICON_NORMAL:-#FFFFFF}" "${1:-󰀹}"
}

_print_fmt () {
    for i in "${OPTIONS[@]}"; do
        printf "%s\0icon\x1f%s\n" "${i%=*}" "$(iconify ${i#*=})"
    done
}

OPTIONS=(
    "ree=e"
    "eer=r"
)



printf "Test Entry\0icon\x1forg.mozilla.Firefox\x1fmeta\x1ffirefox
Test Entry 2\0icon\x1fpath-combine\x1fmeta\x1fpath" | rofi -dmenu

