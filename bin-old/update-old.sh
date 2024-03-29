#!/usr/bin/dash
IFS="$(printf '\n\t')"

if [ "$(whoami)" = root ]; then
    echo "Error, ${0##*/} must be run as a normal user."
    exit 1
fi

_head() {
    printf '\033[0;1m[\033[%sm%s\033[0;1m]\033[0m\n' "${1:-$distro_color}" "${2:?Put header here}"
}
distro_color="$(grep -oP '^ANSI_COLOR="\K[^"]*' /etc/os-release)"
[ "${distro_color:-x}" = x ] && distro_color='31'

confirm=''
case "${1:-}" in
--noconfirm | -y)
    confirm=' -y'
    ;;
esac

if command -v dnf >/dev/null; then
    dnfflags="upgrade --refresh$confirm"
    _head "$distro_color" dnf
    sudo dnf upgrade --refresh
fi

if command -v pacman >/dev/null; then
    if command -v informant >/dev/null; then
        _head 94 informant
        sudo informant check || sudo informant read
    else
        echo "Please install 'informant' to be notified of breaking Arch changes!"
    fi
    if [ "${confirm:-x}" = x ]; then
        if command -v yay >/dev/null; then
            _head "${distro_color}" yay
            yay -Syyu --devel
        else
            _head "${distro_color}" pacman
            sudo pacman -Syyu
        fi
    else
        echo "pacman --noconfirm is dangerous! Skipping pacman updates!"
    fi
    # run this last to make sure pacman lock is not messed with while updating
    if command -v pkgfile &>/dev/null; then
        _head 35 pkgfile
        [ ! -d /var/cache/pkgfile ] && sudo mkdir -p /var/cache/pkgfile
        sudo pkgfile --update
    fi
    _head 35 'pacman -Fy'
    sudo pacman -Fy
fi

if command -v apt >/dev/null; then
    _head 91 'apt'
    aptflags="upgrade${confirm}"
    sudo apt update
    sudo apt $aptflags
fi

distrobox_script="command -v yay >/dev/null 2>&1 && yay -Syu --noconfirm;\
command -v pacman >/dev/null 2>&1 && sudo pacman -Syu --noconfirm;\
command -v dnf >/dev/null 2>&1 && sudo dnf upgrade --refresh -y;\
command -v apt >/dev/null 2>&1 && sudo apt update && sudo apt upgrade -y"

if [ "${confirm:-x}" = x ] && command -v distrobox >/dev/null; then
    boxes="$(distrobox ls --no-color 2>/dev/null | cut -d '|' -f 2 | tail -n '+2' | sed 's/^[ ]*//g ; s/[ ]*$//g')"
    for i in $boxes; do
        _head 96 "distrobox $i"
        echo "entering distrobox $i"
        distrobox-enter -n "$i" -- /bin/sh -c "$distrobox_script"
    done
fi

#if [ -d "$HOME/.local/opt/codium" ] && command -v codium-install.sh >/dev/null; then
#    _head 94 'codium'
#    codium-install.sh
#fi

# vlk-install.sh --update

if command -v flatpak >/dev/null; then
    _head 34 'flatpak'
    flatflags="update${confirm}"
    flatpak $flatflags
fi

if command -v cargo-install-update >/dev/null; then
    _head 33 'cargo'
    cargo install-update -a -g
fi

wait
echo "Done with updates!"
