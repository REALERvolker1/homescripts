#!/usr/bin/env bash
# The script to generate dbus code
set -euo pipefail

echo "WARNING: I have made custom changes to the generated code! Use this with caution!!!
Script will now exit"
exit 1

XMLGEN_DIR="$PWD/src/modules"

# A function to print an error message and exit
_panic() {
    printf '%s\n' "$@" >&2
    exit 1
}

command -v zbus-xmlgen &>/dev/null || _panic \
    "Error, please install zbus-xmlgen!" \
    "https://github.com/dbus2/zbus/tree/main/zbus_xmlgen" \
    'or' \
    "cargo install zbus_xmlgen"

# dependency check
declare -a faildeps=()
for i in busctl mkdir; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing required dependencies:" "${faildeps[@]}"

_find_dbus() {
    local interface="$1"
    local path="$2"
    local modname="$3"
    local modpath="$XMLGEN_DIR/$modname"
    [[ ! -d "$modpath" ]] && mkdir -p "$modpath"

    zbus-xmlgen --system "$interface" "$path" >"$modpath/xmlgen.rs" ||
        _panic "Error, failed to generate $modname/xmlgen.rs"
}

_find_dbus org.freedesktop.UPower /org/freedesktop/UPower/devices/DisplayDevice upower
_find_dbus org.supergfxctl.Daemon /org/supergfxctl/Gfx supergfxd
_find_dbus net.hadess.PowerProfiles /net/hadess/PowerProfiles power_profiles
_find_dbus org.asuslinux.Daemon /org/asuslinux/Platform asusd
# zbus-xmlgen --system org.asuslinux.Daemon /org/asuslinux/Platform >"$XMLGEN_DIR/upower/asusd_xmlgen.rs"
