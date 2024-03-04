#!/usr/bin/env bash
# shitty-fzf, a script by vlk to emulate fzf on inferior computers that do not have fzf installed
set -eo pipefail
IFS=$'\n\t'

declare -r ME="${0##*/}"

case "${1-}" in
--take-input)
    # This script calls itself again but without the input piped into it, so that it can read your answers.
    read -rp '[<number>] > ' selected

    case "$selected" in
    '' | *[!0-9]*)
        echo "Invalid input" >&2
        exit 1
        ;;
    *)
        echo "$selected"
        exit 0
        ;;
    esac
    ;;
*)
    if [[ -t 0 ]]; then
        echo "Must be run with stdin piped, like 'cmd | $ME'" >&2
        exit 1
    fi
    ;;
esac

if ! [[ -t 1 && -t 2 ]]; then
    echo "Must be run with stdout and stderr exposed to the terminal" >&2
    exit 1
fi

echo "Starting $ME STDIN listener" >&2

declare -a slurped
declare -i count=0

while read -r line; do
    # slurped+=("$line")
    slurped[count]="$line"
    count+=1
done

echo "
Received $count lines
=>
" >&2

# I was going to make an overengineered solution to not print everything just in case there was more
# output than the terminal height, but I genuinely don't give a fuck about this script I hopefully
# never have to use

for id in "${!slurped[@]}"; do
    echo "$id"$'\t'"${slurped[$id]}"
done

# This script is broken -- it can't take any more stdin after all that.
read -rp '[<number>] > ' selected

case "$selected" in
'' | *[!0-9]*)
    echo "Invalid input: '$selected'" >&2
    exit 1
    ;;
*)
    echo "${slurped[$selected]}"
    ;;
esac
