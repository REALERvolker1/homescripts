#!/bin/bash

me="${USER:=$(whoami)}"

__check_root() {
    local opt="${1-}"
    if [[ $me == 'root' && $opt == --user ]]; then
        echo "Error, this option must be run as a regular user!"
    elif [[ $me != 'root' && $opt != --user ]]; then
        echo "Error, this script must be run as root!"
        exit 1
    else
        echo "User check successful. Continuing..."
    fi
}

case "${1:-}" in
--chaotic-aur)
    __check_root
    echo "Adding Chaotic AUR to your pacman config"
    key=3056513887B78AEB
    pacman-key --recv-key "$key" --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key "$key"
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    printf '%s\n' '[chaotic-aur]' 'Include = /etc/pacman.d/chaotic-mirrorlist' >>/etc/pacman.conf
    pacman -Syyu
    ;;
--asus)
    __check_root
    echo "Adding Asus-Linux repo to your pacman config"
    key='8F654886F17D497FEFE3DB448B15A6B0E9A3FA35'
    pacman-key --recv-keys "$key"
    pacman-key --finger "$key"
    pacman-key --lsign-key "$key"
    pacman-key --finger "$key"
    printf '%s\n' '[g14]' 'Server = https://arch.asus-linux.org' >>/etc/pacman.conf
    ;;
--xanmod-key-fix)
    __check_root --user
    echo "This adds Linus Torvalds' key to your keyring
because apparently he is very untrustworthy. Go figure.

This is required for xanmod kernel to build properly."

    gpg --keyserver hkps://pgp.surf.nl --recv-keys ABAF11C65A2970B130ABE3C479BE3E4300411886
    ;;
*)
    echo "${0##*/} ${1-}
Invalid argument

Root options
--chaotic-aur     add chaotic aur repos
--asus            add asus-linux g14 repos

Regular user options
--xanmod-key-fix    Sign Linus Torvalds key to fix xanmod kernel builds

More to come, probably idk lol"
    ;;
esac
