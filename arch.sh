#!/bin/bash

if [[ ${USER:=$(whoami)} != 'root' ]]; then
    echo "Error, this script must be run as root!"
    exit 1
fi

case "${1:-}" in
--chaotic-aur)
    key=3056513887B78AEB
    pacman-key --recv-key "$key" --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key "$key"
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    printf '%s\n' '[chaotic-aur]' 'Include = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
    pacman -Syyu
    ;;
--asus)
    key='8F654886F17D497FEFE3DB448B15A6B0E9A3FA35'
    pacman-key --recv-keys "$key"
    pacman-key --finger "$key"
    pacman-key --lsign-key "$key"
    pacman-key --finger "$key"
    printf '%s\n' '[g14]' 'Server = https://arch.asus-linux.org' >> /etc/pacman.conf
    ;;
*)
    echo "${0##*/}"
    printf '%s\t%s\n' \
        "--chaotic-aur" 'add chaotic aur repos' \
        '--asus' 'add asus-linux g14 repos'
    ;;
esac
exit 0
# This script is really just a glorified documentation right now.
cat <<ARCHBTW

EFI stuff
mkfs.fat -F 32 /dev/efi_system_partition

mount --mkdir /dev/efi_part /mnt/boot

mkswap /dev/swap_partition
swapon /dev/swap_partition

pacstrap -K /mnt base linux linux-firmware intel-ucode grub sudo neovim btrfs-progs

Mount options

noatime,compress=zstd:5,ssd,subvol=@{,home,var}

chaotic AUR

ARCHBTW
