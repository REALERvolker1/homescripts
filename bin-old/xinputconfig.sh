#!/usr/bin/bash

_panic() {
    local -i retval=1
    if [[ "${1:-}" == --nice ]]; then
        retval=0
        shift 1
    fi
    printf '%s\n' "$@"
    exit $retval
}

faildeps=()
for i in zenity grep; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Missing dependencies" "${faildeps[@]}"
