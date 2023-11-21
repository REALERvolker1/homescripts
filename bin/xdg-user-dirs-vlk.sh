#!/usr/bin/bash
set -euo pipefail
# generator for $XDG_CONFIG_HOME/user-dirs.dirs
declare -a faildeps=()
for i in 'xdg-user-dirs-update' mkdir cp rm; do
    command -v "$i" >/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && echo "Error, missing dependencies: ${faildeps[*]}" && exit 1

# ensure XDG dirs
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# [xdg-user-dir]="newdir(default to remove)"
declare -A dirs=(
    [DESKTOP]="$HOME/random($HOME/Desktop)"
    [DOWNLOAD]="$HOME/Downloads"
    [TEMPLATES]="$XDG_DATA_HOME/Templates($HOME/Templates)"
    [PUBLICSHARE]="$HOME/random($HOME/Public)"
    [DOCUMENTS]="$HOME/Documents"
    [MUSIC]="$HOME/Music"
    [PICTURES]="$HOME/Pictures"
    [VIDEOS]="$HOME/Videos"
)

xdg-user-dirs-update # reset everything lol

for i in "${!dirs[@]}"; do
    dir="${dirs[$i]}"
    if [[ $dir == *\(*\) ]]; then
        # parse removal format
        rmdir="${dir##*(}"
        rmdir="${rmdir%)*}"
        dir="${dir%(*}"
        if [[ -e $rmdir ]]; then
            stuff="$(printf '%s\n' "$rmdir"/*)"
            if [[ $stuff != "$rmdir/*" ]]; then
                # if it's empty then the glob will just be literal
                for count in {1..9999}; do
                    # a while loop would not work for some reason
                    targetdir="$dir/${rmdir##*/}_$count"
                    [[ ! -e $targetdir ]] && break
                done
                [[ -e $targetdir ]] && echo "Error, $targetdir already exists! Aborting" && exit 1
                echo "moving contents of $rmdir to $targetdir"
                mkdir -p "$targetdir"
                # mv is a bit more volatile than cp
                cp -ri "$rmdir"/* "$targetdir"
            fi
            rm -rf "$rmdir"
            echo "removed $rmdir"
        fi
    fi
    [[ ! -d $dir ]] && mkdir -p "$dir" && echo "made directory $dir"
    xdg-user-dirs-update --set "$i" "$dir" && echo "$i => $dir"
done
