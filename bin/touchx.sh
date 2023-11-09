#!/usr/bin/env bash

set -eu

files=()
editor='echo "new executable created:"'
executable=''

help_function() {
    cat <<EOF
$0
--exec      make the files executable
--codium    open files in vscodium
--nvim      open files in nvim
EOF
    exit 1
}

[ -z "${1:-}" ] && help_function

for arg in "$@"; do
    case "$arg" in
    '--codium')
        editor="codium"
        ;;
    '--nvim')
        editor="nvim"
        ;;
    '--exec')
        executable=1
        ;;
    *-h*)
        help_function
        ;;
    *)
        files+=("$arg")
        ;;
    esac
done

for file in "${files[@]}"; do
    touch "$file"
    ((executable == 1)) && chmod +x "$file"
    sh -c "$editor '$file'"
done
