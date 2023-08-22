#!/usr/bin/env bash

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

original_stty="$(stty --save)"

export HISTFILE="${SHELLHIST:-/dev/null}"

if [ -n "${stdin[*]}" ] && [ -n "$*" ]; then
    printf '%s\n' "${stdin[@]}" | $shellsel "${args[@]}"
elif [ -n "${stdin[*]}" ] && [ -z "$*" ]; then
    printf '%s\n' "${stdin[@]}" | $shellsel
elif [ -z "${stdin[*]}" ] && [ -n "$*" ]; then
    $shellsel "${args[@]}"
else
    $shellsel
fi

stty "$original_stty" && echo "I restored your stty settings for ya :D"
