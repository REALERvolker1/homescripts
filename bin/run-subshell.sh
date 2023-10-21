#!/usr/bin/bash

shellsel="$1"
shift 1
command -v "$shellsel" >/dev/null || exit 1

original_stty="$(stty --save && echo "Saved stty settings" >&2)"
export HISTFILE="${SHELLHIST:-/dev/null}"

$shellsel "$@"

retval="$?"

stty "$original_stty" && echo "Restored stty settings" >&2
exit "$retval"
