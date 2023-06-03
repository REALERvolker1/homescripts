#!/usr/bin/bash

CHEAT_FILE="$XDG_RUNTIME_DIR/dumbfetch_cheat_file.txt"

info_file="$(cat "$CHEAT_FILE")"

props=(
    "$((${SHLVL:-1} - 1))"
    "$(uptime -p | sed 's/^up // ; s/hour/hr/g ; s/minute/min/g')"
    "${TERM:-Undefined}"
    "$(echo "$info_file" | cut -f 1)"
    "$(echo "$info_file" | cut -f 2)"
    "$(echo "$info_file" | cut -f 3)"
)

len=0
for i in "${props[@]}"; do
    ((${#i} > len)) && len="${#i}"
done

echo "$len"

