#!/bin/bash

#if [[ ${USER:=$(whoami)} != 'root' ]]; then
#    echo "Error, this script must be run as root!"
#    exit 1
#fi

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


ARCHBTW
