#!/usr/bin/bash
# foldersync by vlk
# Some programs shit themselves when they encounter symlinks instead of normal folders. This fixes that

folder_root="$HOME/dotfiles"

linked_folders=(
    ".config/fontconfig"
    ".config/Kvantum"
    ".config/gtk-2.0"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
)

for i in "${linked_folders[@]}"; do
    if [ -d "${folder_root}/$i" ] && [ ! -d "$HOME/$i" ]; then
        cp -ru "$folder_root/$i" "$HOME/$i" && echo "updated $folder_root/$i"
    else
        cp -ru "$HOME/$i" "$folder_root/$i" && echo "updated $folder_root/$i"
    fi
done

# copies all the folders I don't have permission to symlink
perm_folders=(
    "/etc/zshenv"
    "/etc/X11/xorg.conf.d/30-mouse.conf"
    "/etc/X11/xorg.conf.d/31-touchpad.conf"
    "/etc/profile.d/lang.sh"
    "/usr/local/bin/numlock-tty.sh"
    "/etc/sysctl.conf"
    "/etc/systemd/system/getty@tty1.service.d"
    "/etc/dnf/dnf.conf"
)

for i in "${perm_folders[@]}"; do
    folderpath="$folder_root/disk-root$i"
    mkdir -p "$(dirname "$folderpath")"
    cp -ru "$i" "$folderpath" && echo "updated $folderpath"
done

