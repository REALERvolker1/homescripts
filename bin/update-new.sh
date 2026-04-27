#!/usr/bin/env bash
# shellcheck shell=bash
# a script that does a thing.
IFS=$'\n\t'

if [ "${USER:=$(whoami)}" = root ]; then
    echo "Error, ${0##*/} must be run as a normal user."
    exit 1
fi

declare -a yes=()
[[ ${1-} == --shutdown ]] && command -v systemctl &>/dev/null && SHUTDOWN=1
if [[ ${1-} == -y ]]; then
    yes=(-y)
fi

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

sudo -vn &>/dev/null || echo "This script requires sudo"
sudo -v

export RUSTFLAGS='-Ctarget-cpu=native'

if [[ -f /etc/os-release ]]; then
    DISTRO_COLOR="$(grep -oP '^ANSI_COLOR="\K[^"]*' /etc/os-release || echo '31')"
else
    DISTRO_COLOR=31
fi
readonly DISTRO_COLOR

export RUSTFLAGS="${RUSTFLAGS:--C target-cpu=native}"

if cmd apt; then
    unsafe
    if cmd nala; then
        _head ' nala'
        sudo nala update && sudo nala upgrade "${yes[@]}"
    else
        _head ' apt'
        sudo apt update && sudo apt upgrade "${yes[@]}"
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
    if cmd paru; then
        _head ' paru'
        unsafe paru -Syu --sudoloop "${yes[@]/y/-noconfirm}"
    elif cmd yay; then
        _head ' yay'
        unsafe yay -Syyu --devel --sudoloop --noremovemake "${yes[@]/y/-noconfirm}"
    else
        _head ' pacman'
        unsafe sudo pacman -Syyu "${yes[@]/y/-noconfirm}"
    fi
    # if cmd reflector; then
    # unsafe sudo reflector '@/etc/xdg/reflector/reflector.conf' --save '/etc/pacman.d/mirrorlist' &
    # fi
    if cmd pkgfile; then
        _head "Backgrounding pkgfile" 95
        [ ! -d /var/cache/pkgfile ] && sudo mkdir -p /var/cache/pkgfile
        unsafe sudo pkgfile --update &>/dev/null &
    fi
    # _head "Backgrounding pacman -Fy" 35
    # unsafe sudo pacman -Fy &>/dev/null &
fi
unsafe sysdboot.sh update --no-mkinitcpio --no-interactive
(
    # update this every other day
    if cmd rustup && (($(date +'%d') % 2)); then
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
    unsafe distrobox upgrade --all
fi

# if cmd pipx; then
# _head '󰌠 pipx' 93
# unsafe pipx upgrade-all
# fi

if (($(jobs -r | wc -l))); then
    echo "Waiting for background jobs to finish"
    jobs
fi
wait
echo "Done with updates!"
#((${SHUTDOWN:-0})) && systemctl poweroff || :
