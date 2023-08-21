#!/usr/bin/bash
# script by vlk to manage my wallpapers cross-wm
# shellcheck disable=2126
set -euo pipefail
IFS=$'\n\t'

background_dir="${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds"
declare -a BACKGROUNDS
for i in "$background_dir/subnautica"/*; do
    BACKGROUNDS+=("$i")
done

MAX_DEDUP_REFRESH=3
MAX_DEDUP_BUFFER=1

declare -r cachefile="${XDG_CACHE_HOME:-$HOME/.cache}/vlkbg.txt"
if [ ! -f "$cachefile" ]; then
    touch -- "$cachefile"
fi

declare -a CLI_IMAGES

for i in "$@"; do
    parsed_i="${i#*=}"
    case "$i" in
    '--image='*)
        if [ -f "$parsed_i" ]; then
            CLI_IMAGES+=("$parsed_i")
        else
            echo "Error, Could not find image file: '$parsed_i'"
            if [[ "${parsed_i::1}" = '~' ]]; then
                echo "all tildes must be expanded (for example, ~ into $HOME)"
            fi
        fi
        ;;
    '--backend='*)
        BACKEND="$parsed_i"
        ;;
    '--monitor-count='*)
        MONITOR_COUNT="$parsed_i"
        ;;
    *)
        printf '%s\n' \
            "Unrecognized option: '$i'" \
            "Usage: ${0##*/} --arg1 --arg2" \
            '' \
            "--image=/path/to/image   Path to image file(s)" \
            "    Pass multiple images through '${0##*/} --image=/path --image=/path'" \
            '' \
            "--backend=BACKEND_TYPE   Override backend" \
            "    Available backends:" \
            "===Xorg===     ===Wayland===" \
            "hsetroot       hyprpaper" \
            "nitrogen       swaybg" \
            '' \
            "--monitor-count=INT      Override monitor count with a number [0-9]" \
            "    Tries to set the background of x monitors"
        exit 1
        ;;
    esac
done

if [ -z "${BACKEND:-}" ]; then
    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        if command -v hsetroot >/dev/null; then
            BACKEND=hsetroot
        elif command -v nitrogen >/dev/null; then
            BACKEND=nitrogen
        else
            echo "Error, neither hsetroot nor nitrogen is installed. Xorg backend cannot function."
            exit 1
        fi
    else
        if command -v hyprpaper >/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            BACKEND=hyprpaper
        elif command -v swaybg >/dev/null; then
            BACKEND=swaybg
        else
            echo "Error, neither hyprpaper nor swaybg is installed. Wayland backend cannot function."
            exit 1
        fi
    fi
fi

if [ -z "${MONITOR_COUNT:-}" ]; then
    if [[ "$BACKEND" == 'hsetroot' ]] || [[ "$BACKEND" == 'swaybg' ]]; then
        MONITOR_COUNT=1
    else
        MONITOR_COUNT="$(grep '^connected' /sys/class/drm/card*/status | wc -l)"
    fi
fi

declare -a IMAGES
declare -i images_count="$MONITOR_COUNT"
if [ -n "${CLI_IMAGES:-}" ]; then
    for i in "${CLI_IMAGES[@]}"; do
        if ((images_count <= 0)); then
            break
        else
            IMAGES+=("$i")
            images_count=$((images_count - 1))
        fi
    done
fi
if ((images_count > 0)); then
    cachefile_contents="$(cat "$cachefile")"
    potential_backgrounds_count="${#BACKGROUNDS[@]}"
    if ((potential_backgrounds_count < $((MAX_DEDUP_REFRESH + images_count + MAX_DEDUP_BUFFER)))); then
        echo "Error, not enough backgrounds in selection to satisfy your MAX_DEDUP_REFRESH count of '$MAX_DEDUP_REFRESH'. Disabling background deduplication."
        MAX_DEDUP_REFRESH="$images_count"
    fi

    selected_images="$(
        for i in "${BACKGROUNDS[@]}"; do
            has_line="$(
                # grep bugged out on me for this. Have to use a slower method
                echo "$cachefile_contents" | while read -r line; do
                    if [[ "$line" == "$i" ]]; then
                        echo true
                    fi
                done
            )"
            if [ -z "${has_line:-}" ]; then
                echo "$i"
            fi
        done | shuf -n "$images_count"
    )"
    (
        echo "$selected_images"
        head -n $((MAX_DEDUP_REFRESH - images_count)) <<<"$cachefile_contents"
    ) >"$cachefile"
    for i in $selected_images; do
        IMAGES+=("$i")
    done
fi

echo "$0 --backend='$BACKEND' --monitor-count='$MONITOR_COUNT' $(printf -- '--image=%s ' "${IMAGES[@]}")"

if pgrep 'swaybg' >/dev/null; then
    echo "Found an instance of swaybg. Killing..."
    killall swaybg
fi

case "$BACKEND" in
'hsetroot')
    hsetroot -cover "${IMAGES[0]}"
    ;;
'nitrogen')
    declare -i count=0
    for i in "${IMAGES[@]}"; do
        echo nitrogen --set-zoom-fill --head="$count" "$i"
        count=$((count + 1))
    done
    ;;
'swaybg')
    (
        set -m
        swaybg -m fill -i "${IMAGES[0]}" &
    )
    ;;
'hyprpaper')
    if pgrep 'hyprpaper' >/dev/null; then
        for i in "${IMAGES[@]}"; do
            hyprctl hyprpaper preload "$i"
        done
        declare -i count=0
        for i in $(hyprctl monitors | grep -oP '^Monitor \K[^ ]*'); do
            hyprctl hyprpaper wallpaper "$i,${IMAGES[$count]}"
            count=$((count + 1))
        done
        hyprctl hyprpaper unload all
    else
        (
            set -m
            hyprpaper -c <(
                printf 'preload = %s\n' "${IMAGES[@]}"
                declare -i count=0
                for i in $(hyprctl monitors | grep -oP '^Monitor \K[^ ]*'); do
                    echo "wallpaper = $i,${IMAGES[$count]}"
                    count=$((count + 1))
                done
            ) &
        )
    fi
    ;;

esac
