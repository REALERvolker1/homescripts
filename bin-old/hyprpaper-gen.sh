#!/usr/bin/bash
# shellcheck shell=bash
# a script that does a thing.
set -euo pipefail
IFS=$'\n\t'

# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

: "${XDG_DATA_HOME:=$HOME/.local/share}" "${XDG_CONFIG_HOME:=$HOME/.config}"

# dependency check
declare -a faildeps=()
for i in hyprpaper realpath cat; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

# argparse
defaultcfg="$XDG_CONFIG_HOME/hypr/hyprpaper.conf"
configpath="$defaultcfg"

bgdir="$XDG_DATA_HOME/backgrounds"

case "$(grep -oP '^NAME="\K[^" ]+' /etc/os-release || :)" in
Arch)
    defaultwallpaper="$bgdir/arch/Arch-1920x1080-hyprland-epstein-flight-logs.png"
    ;;
Fedora)
    defaultwallpaper="$bgdir/fedora/Fedora-1920x1080-hyprland-logs.png"
    ;;
esac

wallpaper="$defaultwallpaper"

for i in "$@"; do
    case "${i:=}" in
    --cfgpath=*)
        configpath="${i#*=}"
        ;;
    --wallpaper=*)
        wallpaper="${i#*=}"
        ;;
    *)
        cat <<BRUH
Error, invalid arg passed! '$i'

Valid arguments include:
--cfgpath=/path/to/configfile   custom config path
Default is: $defaultcfg

--wallpaper=/path/to/wallpaper  Custom wallpaper path
Default is: $defaultwallpaper

Edit the script to modify specific values

BRUH
        exit 2
        ;;
    esac
done

[[ ! -f $wallpaper ]] && _panic "Error, could not determine wallpaper!"

config_path="$(realpath "$configpath")"

[[ -d ${config_path%/*} ]] || mkdir "${config_path%/*}"

if [[ -e $config_path ]]; then
    read -r -p "$config_path already exists! Clobber? [y/N] > " clobberanswer
    [[ ${clobberanswer:-} == y ]] || _panic "Chose not to clobber $config_path"
fi

cat >"$config_path" <<EOF
preload=$wallpaper
wallpaper = eDP-1, $wallpaper
wallpaper = DP-1, $wallpaper
EOF
