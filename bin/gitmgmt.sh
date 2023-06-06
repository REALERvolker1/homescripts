#!/usr/bin/bash

set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

clone_func () { # (url: %s<url>, clone_command: %s<cmd<git>>|Undefined) -> folder_name: %s<fs>
    local url="${1:?Error, please specify a url!}"
    local clone_command="${2:-git clone}"

    folder_name="${GITMGMT_HOME:-$XDG_DATA_HOME/gitmgmt}/${url##*/}"
    [ -e "$folder_name" ] && rm -rf "$folder_name"

    $clone_command "$url" "$folder_name"
}

check_update () {
    
}

change_cwd () {
    cd "${folder_name:?Error, undefined folder name}" || {
        echo "Error, incorrect folder name! please specify a name in the script ${0:-}"
        exit 1
    }
}

safelink () {
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

binlink () {
    local file="${1:?Error, please input a path to a binary}"
    local link_name="${2:-$(basename "$file")}"
    safelink "$file" "$HOME/.local/bin" "$link_name"
}

case "${1:-}" in
    '--source')
        return
    ;;
    *)
        set +euo pipefail
        echo 'gitmgmt updating'
        for file in "$XDG_CONFIG_HOME/gitmgmt"/*; do
            echo "$file"
        done
    ;;
esac

