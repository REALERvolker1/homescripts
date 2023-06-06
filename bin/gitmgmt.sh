#!/usr/bin/bash
set -euo pipefail

_panic () {
    echo "[PANIC] $*"
    exit 1
}
_log () {
    echo "[LOG] $*" >&2
}

_reset_parser () {
    printf "local %s='%s'\n" \
        "clone_command" "git clone" \
        "url" "" \
        "commands" ""
}

parse_config () {
    local config_file
    config_file="$(cat "$GITMGMT_CONFIG_HOME/config.ini")"
    local IFS=$'\n'
    local iprop
    local ival
    GITS=()
    #eval "$(_reset_parser)"
    for i in $config_file; do
        [[ "$i" == "#"* ]] || [ -z "${i:-}" ] && continue
        [ "$i" = "[pkg]" ] && eval "$(_reset_parser)" && continue
        if [ "$i" = "[endpkg]" ]; then
            GITS+=("clone_command=$clone_command
url=$url
commands=$commands")
            eval "$(_reset_parser)"
        fi

        iprop="${i%%=*}"
        ival="$(echo "${i#*=}" | cut -d '"' -f 2)"
        case "$iprop" in
            'clone_command')
                clone_command="$ival"
                ;;
            'url')
                url="$ival"
                ;;
            'commands')
                commands="$ival"
                ;;
        esac
    done
}

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
GITMGMT_HOME="${GITMGMT_HOME:-$XDG_DATA_HOME/gitmgmt}"
GITMGMT_CONFIG_HOME="${GITMGMT_CONFIG_HOME:-$XDG_CONFIG_HOME/gitmgmt}"

for dir in "$GITMGMT_HOME" "$GITMGMT_CONFIG_HOME"; do
    [ ! -d "$dir" ] && mkdir -p "$dir" && _log "created $dir"
done

parse_config

for repo in "${GITS[@]}"; do
    directory=
    oldifs="$IFS"
    IFS=$'\n'
    for opt in $repo; do
        echo "= $opt ="
    done
    IFS="$oldifs"
done
