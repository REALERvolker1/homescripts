#!/usr/bin/bash
# set -euo pipefail
# This script is meant to be used internally as a library. Example:

# #!/usr/bin/bash
# # A script that runs vscodium
# FLATPAK_NAMES="com.vscodium.codium:com.visualstudio.code-oss:com.visualstudio.code"
# BIN_NAMES="codium:code-oss:code"
# PREFERS_FLATPAK=''
# alternative home directory if you want to isolate stuff. Gets exported as $HOME.
# If you use this, it is recommended to set `MAIN_HOMEDIR="$HOME"` to keep a reference to the original
# ALT_HOMEDIR="$XDG_CACHE_HOME/codium-home"

# Optional: Make it respond to --flatpak arg. disabled by default cuz compatibility
# PREFERS_FLATPAK can be set to a non-empty string to prefer flatpak over binary.
# if [[ ${1-} == '--flatpak' ]]; then
#     shift 1
#     PREFERS_FLATPAK=ye
# fi

# source flatpak-fallback.sh

# exec "${result_command[@]}" "$@"

cmd() {
    command -v "$@" &>/dev/null
}

_panic() {
    echo "$@" >&2
    exit 1
}

_env_panic() {
    _panic "Environment variable $1 is not set!" \
        "Please set it to any colon-separated list of $2."
}

# Configure these with environment variables. The args are directly passed.
[[ -z ${FLATPAK_NAMES-} ]] && _env_panic FLATPAK_NAMES "Flatpak IDs"
[[ -z ${BIN_NAMES-} ]] && _env_panic FLATPAK_NAMES "Flatpak IDs"

# Input: Flatpak names as array. Side affects: resets ${result_command[@]} array.
_load_flatpak() {
    (($#)) || return
    local arg flatpak

    local oldifs="$IFS"
    local IFS="|"
    local grep_args="^($*)$"
    IFS="$oldifs"

    local matches
    matches=$(flatpak list --app --columns=application | grep -E "$grep_args" || :)
    [[ -z ${matches-} ]] && return

    for arg in "$@"; do
        while read -r flatpak; do
            if [[ ${arg-} == "${flatpak-}" ]]; then
                result_command=(flatpak run "$flatpak")
                RESULT_NAME="$flatpak"
                IS_BINARY=0
                return
            fi
        done <<<"$matches"
    done
    return
}

# Input: executable file names as array. Side affects: resets ${result_command[@]} array.
_load_binary() {
    local source_file
    source_file="$(realpath "$0")"

    local bin bin_path abs_bin_path
    for bin in "$@"; do
        while read -r bin_path; do
            abs_bin_path=$(realpath "$bin_path")
            if [[ -x ${abs_bin_path-} && "${abs_bin_path-}" != "$source_file" ]]; then
                result_command=("$bin_path")
                RESULT_NAME="$bin_path"
                IS_BINARY=1
                return
            fi
        done < <(which -a "$bin" 2>/dev/null || :)
    done
    return
}

declare -i IS_BINARY

OLDIFS="$IFS"
IFS=":"

declare -a flatpak_names bin_names

read -r -a flatpak_names <<<"$FLATPAK_NAMES"
read -r -a bin_names <<<"$BIN_NAMES"

IFS="$OLDIFS"

# printf '=%s\n' flatpak "${flatpak_names[@]}" '' bin "${bin_names[@]}"
declare -a result_command=()

if cmd flatpak; then
    if [[ -n ${PREFERS_FLATPAK-} ]]; then
        echo prefers flatpak
        _load_flatpak "${flatpak_names[@]}"
        ((${#result_command[@]})) || _load_binary "${bin_names[@]}"
    else
        _load_binary "${bin_names[@]}"
        ((${#result_command[@]})) || _load_flatpak "${flatpak_names[@]}"
    fi
else
    _load_binary "${bin_names[@]}"
fi

if [[ -n ${ALT_HOMEDIR-} ]]; then
    if cmd bwrap; then
        [[ ! -d ${ALT_HOMEDIR-} ]] && mkdir -p "$ALT_HOMEDIR"
        export HOME="$ALT_HOMEDIR"
        result_command=(bwrap --dev-bind / / --setenv HOME "$ALT_HOMEDIR" "${result_command[@]}")
    else
        echo "bwrap not found, falling back to regular homedir"
    fi
fi

((${#result_command[@]})) || _panic "Failed to find a command or flatpak!"

# exec "${result_command[@]}" "$@"
