#!/usr/bin/dash

if ! command -v xinput >/dev/null; then
    echo "Missing xinput!"
    exit 1
fi

mouse_props=''

# xinput | grep -oE '(ASUP1205:00 093A:2003 Touchpad|Glorious Model O (|Wireless))\s+id=[0-9]+'
# xinput | grep -oP 'id=\K[0-9]+(?=\s*\[slave\s*pointer)'
# xinput | grep -oP 'id=\K[0-9]+(?=\s*\[slave\s*pointer)' | while read -r i; do
#     echo "$i"
# done

devices="$(xinput | grep -oE '(ASUP1205:00 093A:2003 Touchpad|Glorious Model O (|Wireless))\s+id=[0-9]+')"
