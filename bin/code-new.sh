#!/usr/bin/env bash

if [[ ${1-} == '--flatpak' ]]; then
    shift 1
    PREFERS_FLATPAK=ye
fi

if [[ "${0##*/}" == 'code' ]]; then
    BIN_NAMES="code:code-oss:codium"
    FLATPAK_NAMES="com.visualstudio.code:com.visualstudio.code-oss:com.vscodium.codium"
else
    BIN_NAMES="codium:code-oss:code"
    FLATPAK_NAMES="com.vscodium.codium:com.visualstudio.code-oss:com.visualstudio.code"
fi
#MAIN_HOMEDIR="$HOME"
#ALT_HOMEDIR="$XDG_CACHE_HOME/codium-home"
[[ -n ${NIXOS_OZONE_WL-} ]] && export NIXOS_OZONE_WL=''

source flatpak-fallback.sh

# code-oss doesn't work with wayland
# [[ ${RESULT_NAME-} == *codium* && -n ${WAYLAND_DISPLAY:-} ]] && result_command+=(--enable-features=UseOzonePlatform --ozone-platform=wayland)

# A really naive way of making it not shit all over my home directory
#(
#    declare -a unshit_paths=(
#        "$MAIN_HOMEDIR/.codeium"
#    )
#    sleep 5
#    for i in "${unshit_paths[@]}"; do
#        [[ -d "$i" ]] && rm -rf "$i"
#    done
#) &

#disown
echo "${result_command[@]}" "$@"
exec "${result_command[@]}" "$@"
