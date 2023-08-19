#!/usr/bin/bash

set -euo pipefail

shellsel="$1"
shift 1
command -v "$shellsel" >/dev/null || exit 1

declare -a stdin
if [ ! -t 0 ]; then
    while read -r line; do
        stdin+=("$line")
    done
    unset line
fi

declare -a args
for line in "$@"; do
    args+=("$line")
done

export HISTFILE="${SHELLHIST:-/dev/null}"

if [ -n "${stdin[*]}" ] && [ -n "$*" ]; then
    printf '%s\n' "${stdin[@]}" | exec $shellsel "${args[@]}"
elif [ -n "${stdin[*]}" ] && [ -z "$*" ]; then
    printf '%s\n' "${stdin[@]}" | exec $shellsel
elif [ -z "${stdin[*]}" ] && [ -n "$*" ]; then
    exec $shellsel "${args[@]}"
else
    exec $shellsel
fi
