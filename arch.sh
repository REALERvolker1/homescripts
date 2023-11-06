#!/bin/bash
# must be run as root

if [[ ${USER:=$(whoami)} != 'root' ]]; then
    echo "Error, this script must be run as root!"
    exit 1
fi

exit 0
for i in "$@"; do
    case "${i:-}" in
    '--livedisk')
        lsblk
        echo "Which drive do you want to install the bootloader on?"
        read -r -p ' > ' boot
        echo "Which drive do you want to install the main system on?"
        read -r -p ' > ' system
        printf '%s\n' \
            "This installation script assumes you have made your partition table already and you want to use btrfs." \
            "If you have already done so, if your name is vlk, and if you truly want to run this script, enter 'y'." \
            'Otherwise the script will exit.'
        read -r -p 'You sure you want to run this? >' LAST_WARNING
        [[ ${LAST_WARNING:-} == y && -n ${system:+x} && -n ${boot:+x} ]] || exit 0
        mkfs.btrfs -L 'archbtw' "$system"
        mount "$system" /mnt
        declare -A subvolumes=(
            [/]=@
            [/home]=@home
            [/var]=@var
        )
        for i in "${subvolumes[@]}"; do
            btrfs subvolume create "$i"
        done
        umount /mnt
        for i in "${!subvolumes[@]}"; do
            mkdir -p "/mnt${i}"
            mount -o "relatime,compress=zstd:5,ssd,subvol=${subvolumes[$i]}" "/mnt${i}"
        done
    ;;

    '--bare-system') ;;

    esac
done
