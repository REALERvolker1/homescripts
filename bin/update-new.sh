#!/usr/bin/bash
# shellcheck shell=bash
# a script that does a thing.
IFS=$'\n\t'

if [ "${USER:=$(whoami)}" = root ]; then
    echo "Error, ${0##*/} must be run as a normal user."
    exit 1
fi

[[ ${1-} == --shutdown ]] && command -v systemctl &>/dev/null && SHUTDOWN=1

unsafe() {
    set +euo pipefail
    if (($#)); then
        "$@"
        safe
    fi
}
safe() { set -euo pipefail; }
safe

_head() {
    local text="${1:?Error, no header text specified!}"
    local color="${2:-$DISTRO_COLOR}"
    local line
    printf -v line "%-${#text}s" ''
    line="${line// /─}──"
    printf '\e[0m%b\e[0m\n' \
        "╭$line╮" \
        "│ \e[1;${color}m$text\e[0m │" \
        "╰$line╯"
}

cmd() { command -v "$@" &>/dev/null; }

if [[ -f /etc/os-release ]]; then
    DISTRO_COLOR="$(grep -oP '^ANSI_COLOR="\K[^"]*' /etc/os-release || echo '31')"
else
    DISTRO_COLOR=31
fi
readonly DISTRO_COLOR

echo "This script requires sudo"
sudo -v

if cmd apt; then
    unsafe
    if cmd nala; then
        _head ' nala'
        sudo nala update && sudo nala upgrade
    else
        _head ' apt'
        sudo apt update && sudo apt upgrade
    fi
    safe
fi

if cmd dnf; then
    _head ' dnf'
    unsafe sudo dnf upgrade --refresh
fi

if cmd pacman; then
    if cmd informant; then
        unsafe
        sudo informant check || sudo informant read
        safe
    else
        echo "Please install 'informant' to be notified of breaking Arch changes!"
    fi
    if cmd yay; then
        _head ' yay'
        unsafe yay -Syyu --devel
    else
        _head ' pacman'
        unsafe sudo pacman -Syyu
    fi
    if cmd pkgfile; then
        _head "Backgrounding pkgfile" 95
        [ ! -d /var/cache/pkgfile ] && sudo mkdir -p /var/cache/pkgfile
        unsafe sudo pkgfile --update &>/dev/null &
    fi
    _head "Backgrounding pacman -Fy" 35
    unsafe sudo pacman -Fy &>/dev/null &
fi

# distrobox_script="if command -v pacman; thensudo pacman -Syu; fi"
distrobox_script="\
if command -v pacman; then\
    if command -v yay; then\
        yay -Syu --devel;\
    else\
        sudo pacman -Syu;\
    fi;\
fi;\
if command -v dnf; then\
    sudo dnf upgrade --refresh;\
fi;\
if command -v apt; then\
    sudo apt update && sudo apt upgrade;\
fi;\
"
(
    if cmd rustup; then
        _head '󱘗 rustup' '38;5;166'
        unsafe rustup update
    fi
    if cmd cargo-install-update; then
        _head '󱘗 cargo' '38;5;166'
        unsafe cargo install-update -a -g
    fi
) &

if cmd flatpak; then
    _head ' flatpak' 94
    unsafe flatpak update -y
fi

if cmd distrobox; then
    _head '󰡨 Distrobox' '38;5;95'
    distrobox upgrade --all
fi
if (($(jobs -r | wc -l))); then
    echo "Waiting for background jobs to finish"
    jobs
fi
wait
echo "Done with updates!"
((${SHUTDOWN:-0})) && systemctl poweroff || :
