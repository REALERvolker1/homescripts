#!/usr/bin/env bash

set -euo pipefail
IFS=$'\r\n\t'

if [[ -z $PROJECT_NAME ]]; then
    PROJECT_NAME="${PWD##*/}"
fi
if [[ -z $BUILDDIR ]]; then
    BUILDDIR="./build"
fi

mkdir -p "$BUILDDIR"

declare -a to_compile=()

compile() {
    if command -v sccache &>/dev/null; then
        sccache cc "$@"
    else
        cc "$@"
    fi
}

search_for_files() {
    for file in "$1"/*; do
        if [[ -d $file ]]; then
            search_for_files "$file"
        else
            to_compile+=("$file")
        fi
    done
}

search_for_files "./src"

compile -O3 -Wall -Wpedantic -Wextra -Werror -std=c23 "$@" -o "$BUILDDIR/$PROJECT_NAME" "${to_compile[@]}"
