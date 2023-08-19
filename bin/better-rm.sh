#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

declare -a files
declare -a errors

for i in "$@"; do
    if [ -e "$i" ]; then
        if [ -w "$i" ]; then
            files+=("$i")
        else
            errors+=("[Read-only] $i")
        fi
    else
        errors+=("[Missing] $i")
    fi
done

# stty_size="$(stty size)"
# height="${stty_size%% *}"
# width="${stty_size##* }"

if [ -n "${errors:-}" ]; then
    echo "There were one or more errors"
    printf '\x1b[1;91m󱪟 %s\x1b[0m\n' "${errors[@]}"
    echo
fi
if [ -n "${files:-}" ]; then
    echo "Files to remove"
    for i in "${files[@]}"; do
        i_display="$(ls -d --color=always "$i")"
        if [ -h "$i" ]; then
            i_target="$(ls -d --color=always "$(realpath "$i")")"
            i_display="$i_display -> $i_target"
        fi
        if [ -d "$i" ]; then
            i_contents="$(ls -A --color=always -1 "$i")"
            i_contents_length="$(echo "$i_contents" | wc -l)"
            if ((i_contents_length > 5)); then
                i_contents="$(
                    echo "$i_contents" | head -n 5
                    echo "And $((i_contents_length - 5)) more..."
                )"
            elif ((i_contents_length < 1)); then
                i_contents="(Empty)"
            fi
            echo "󰉋 $i_display"
            echo "$i_contents" | sed 's/^/  ⮑ /g'
        else
            echo "󰈙 $i_display"
        fi
    done

    printf '%s\n' '' "Do you wish to delete these ${#files[@]} files?"
    printf '\x1b[1m[y/n]\x1b[0m (n) > '
    read answer
    case "${answer:-}" in
    'y')
        echo "Do you want to trash these files, or delete them?"
        printf '\x1b[1m[t/d]\x1b[0m (t) > '
        read answer
        case "${answer:-}" in
        't' | 'T')
            if command -v 'trashds' >/dev/null; then
                trash -rf "${files[@]}" && echo "󰩹 $i"
            else
                trashdir="${XDG_CACHE_HOME:-$HOME/.cache}/better-rm-trash"
                echo "trash-cli not found, moving files to $trashdir"
                mkdir -p "$trashdir"
                for i in "${files[@]}"; do
                    mv -f "$i" "$trashdir" && echo "󰩹 $i"
                done
            fi
            ;;
        'd' | 'D')
            for i in "${files[@]}"; do
                rm -rf "$i" && echo "󰅗 $i"
            done
            ;;
        esac
        ;;
    *)
        echo "action canceled"
        ;;
    esac
fi
