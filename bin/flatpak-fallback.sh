#!/usr/bin/bash
# set -euo pipefail
# This script is meant to be used internally as a library. Example:

# #!/usr/bin/bash
# # A script that runs vscodium
# FLATPAK_NAMES="com.vscodium.codium:com.visualstudio.code-oss:com.visualstudio.code"
# BIN_NAMES="codium:code-oss:code"
# PREFERS_FLATPAK=''

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

# default: prefer binary.
: "${PREFERS_FLATPAK:=false}"

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

    local selected_flatpak
    for arg in "$@"; do
        while read -r flatpak; do
            if [[ ${arg-} == "${flatpak-}" ]]; then
                # We found the flatpak!
                # echo "$flatpak"
                result_command=(flatpak run "$flatpak")
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
                return
            fi
        done < <(which -a "$bin" 2>/dev/null || :)
    done
    return
}

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
        _load_flatpak "${flatpak_names[@]}"
        ((${#result_command[@]})) || _load_binary "${bin_names[@]}"
    else
        _load_binary "${bin_names[@]}"
        ((${#result_command[@]})) || _load_flatpak "${flatpak_names[@]}"
    fi
else
    _load_binary "${bin_names[@]}"
fi

((${#result_command[@]})) || _panic "Failed to find a command or flatpak!"

# exec "${result_command[@]}" "$@"
