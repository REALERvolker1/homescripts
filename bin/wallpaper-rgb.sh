#!/usr/bin/env dash


if [ -z "$2" ]; then
    DELAY=0.25
else
    DELAY="$2"
fi
if [ "$1" = "-d" ]; then
    rainbow | while read -r line; do
        hsetroot -solid "$line"
        sleep "$DELAY"
    done
else
    printf "USAGE:\n  -d <num> => run with optional delay. Default is 0.25."
fi

