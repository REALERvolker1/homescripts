#!/usr/bin/dash

max_diff=5
bgfile="$XDG_CACHE_HOME/vlk-background-sh"
if [ ! -w "$bgfile" ]; then
    touch "$bgfile"
fi
previous_backgrounds="$(cat "$bgfile")"
backgrounds="$(printf '%s\n' "$XDG_DATA_HOME/backgrounds"/*.jpg | shuf)"

if [ "$(echo "$previous_backgrounds" | wc -l)" -ge "$max_diff" ]; then
    echo "$previous_backgrounds" | tail -n $((max_diff - 1)) > "$bgfile"
fi

output () {
    echo -n "$1"
    echo "$1" >> "$bgfile"
}

echo "$backgrounds" | while read -r line; do
    if [ -z "$previous_backgrounds" ]; then
        output "$line"
        break
    fi
    case "$line" in
        *$previous_backgrounds*)
            continue
        ;;
        *)
            output "$line"
            break
        ;;
    esac
done

