#!/usr/bin/bash

CHEAT_FILE="$XDG_RUNTIME_DIR/dumbfetch_cheat_file.txt"

props=(
    "$((${SHLVL:-1} - 1))"
    "$(uptime -p | sed 's/^up // ; s/hour/hr/g ; s/minute/min/g')"
    "${TERM:-Undefined}"
    "$(echo "$info_file" | cut -f 1)"
    "$(echo "$info_file" | cut -f 2)"
    "$(echo "$info_file" | cut -f 3)"
)

len="$(printf '%s\n' "${props[@]}" | wc -L)"
echo "$len"
