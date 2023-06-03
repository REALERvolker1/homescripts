#!/usr/bin/env bash
# vlk script moment
# depends: audacious, file

MUSICDIR="${XDG_MUSIC_DIR:-$HOME/Music}"

get_folder () {
    directory="${1}"
    #folder="${2}"
    #directory="$basepath/$folder"
    if [ -d "$directory" ]; then
        selected="$(ls "$directory" | rofi -dmenu)"
        [ ! -z "$selected" ] && printf "$directory/$selected"
    fi
}
directory="$(get_folder "${MUSICDIR}")"

while :; do
    [ -z "$directory" ] && exit 1
    has_subdirs=false
    for subdir in "$directory"/*; do
        if [ -d "$subdir" ]; then
            has_subdirs=true
        fi
    done
    if [[ "$has_subdirs" == true ]]; then
        directory="$(get_folder "${directory}")"
    else
        files=()
        if [ -d "$directory" ]; then
            for i in "$directory"/* ; do
                if [[ "$(file -bL --mime-type "$i" | cut -d '/' -f 1)" == "audio" ]]; then
                    files+=("$i")
                fi
            done
        else
            if [[ "$(file -bL --mime-type "$directory" | cut -d '/' -f 1)" == "audio" ]]; then
                files+=("$directory")
            fi
        fi
        [ -n "${files[*]}" ] && exec audacious "${files[@]}"
        break
    fi
done
