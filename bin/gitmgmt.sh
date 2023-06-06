#!/usr/bin/bash
# gitmgmt.sh by vlk
# https://github.com/REALERvolker1/homescripts/tree/main/.config/gitmgmt for example scripts

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

clone_func () { # (url: %s<url>, clone_command: %s<cmd<git>>|Undefined) -> folder_name: %s<fs>
    local url="${1:?Error, please specify a url!}"
    local clone_command="${2:-git clone}"

    folder_name="${GITMGMT_HOME:-$XDG_DATA_HOME/gitmgmt}/${url##*/}"
    [ -e "$folder_name" ] && rm -rf "$folder_name"

    $clone_command "$url" "$folder_name"
}

check_update () { # file: %s<fs(/)> -> status
    local folder="${1:?Error, please give a folder name}"
    #local opt="${2:-}"
    [ ! -d "$folder" ] && return
    cd "$folder"
    #local diff_lines
    #diff_lines="$(git fetch && git diff --stat "origin/$(git branch | grep -oP "\*[[:space:]]*\K.*\$")")"
    if git status | grep -q '^Your branch is behind'; then
        echo branch behind
    else
        return 1
    fi
    # [ "$diff_lines" = '' ] && return 1
    # if [ "$opt" = '--print-update' ]; then
    #     echo -e "$folder\n$diff_lines"
    # fi
}

change_cwd () { # folder_name: global %s<fs(/)> -> status
    cd "${folder_name:?Error, undefined folder name}" || {
        echo "Error, incorrect folder name! please specify a name in the script ${0:-}"
        exit 1
    }
}

safelink () { # (file:<fs>, target:<fs>, link_name<fs?>) -> status
    local file="${1:?Error, please input a path to a binary}"
    local target="${2:?Error, please input a target directory}"
    local link_name="${3:-$(basename "$file")}"
    [ ! -e "$file" ] && echo "Error, please select a real file/dir"
    mkdir -p "$(dirname "$target")"
    local bin_name
    bin_name="$target/$link_name"

    if [ -L "$bin_name" ]; then
        rm "$bin_name"
    elif [ -e "$bin_name" ]; then
        echo "Error, '$bin_name' exists!"
        /bin/ls -d --color=auto "$bin_name"
        return 1
    fi
    ln -s "$(realpath -e "$file")" "$bin_name"
}

binlink () { # (file:<fs(.x)>, link_name<fs?>) -> status
    local file="${1:?Error, please input a path to a binary}"
    local link_name="${2:-$(basename "$file")}"
    safelink "$file" "$HOME/.local/bin" "$link_name"
}

case "${1:-}" in
    '--source')
        set -euo pipefail
        return
    ;;
    '--check-update')
        for file in "$XDG_CONFIG_HOME/gitmgmt"/* ; do
            file_url="$(grep -oP '^clone_func \K.*$' "$file" | sed "s/^\"//g ; s/\"$//g; s/^'//g; s/'$//g")"
            folder_name="${GITMGMT_HOME:-$XDG_DATA_HOME/gitmgmt}/${file_url##*/}"
            check_update "$folder_name" --print-update
        done
    ;;
    *)
        echo 'gitmgmt updating'
        declare -a file_errors
        for file in "$XDG_CONFIG_HOME/gitmgmt"/*; do
            file_url="$(grep -oP '^clone_func \K.*$' "$file" | sed "s/^\"//g ; s/\"$//g; s/^'//g; s/'$//g")"
            folder_name="${GITMGMT_HOME:-$XDG_DATA_HOME/gitmgmt}/${file_url##*/}"
            check_update "$folder_name" || [ "${2:-}" = '--force' ] || continue
            sh -c "$file" || file_errors+=("$file")
        done
        if [[ "${file_errors[*]}" != '' ]]; then
            printf '%s\n' 'gitmgmt errors' '=== === ===' "${file_errors[@]}"
        fi
    ;;
esac
