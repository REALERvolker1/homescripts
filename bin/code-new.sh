#!/usr/bin/bash

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

source flatpak-fallback.sh

# code-oss doesn't work with wayland
[[ ${result_command[0]-} == *codium && -n ${WAYLAND_DISPLAY:-} ]] && result_command+=(--enable-features=UseOzonePlatform --ozone-platform=wayland)

echo "${result_command[@]}" "$@"
exec "${result_command[@]}" "$@"
