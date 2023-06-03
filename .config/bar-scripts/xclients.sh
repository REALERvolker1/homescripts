#!/bin/dash
#

case "$1" in
    '--number')
        echo "󱂬 $(xlsclients | wc -l)"
    ;; '--rofi-list')
        xlsclients | sed "s|^${HOSTNAME}[ ]*||g" | rofi -dmenu
    ;; *)
        echo "${0##*/} [--number, --rofi-list]
shsould be self-explanatory"
    ;;
esac

