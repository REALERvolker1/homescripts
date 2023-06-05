#!/usr/bin/bash
# foldersync by vlk
# Some programs shit themselves when they encounter symlinks instead of normal folders. This fixes that

folder_root="$HOME/dotfiles"

linked_folders=(
    ".config/fontconfig"
    ".config/gtk-2.0"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
)

for i in "${linked_folders[@]}"; do
    if [ -d "${folder_root}/$i" ] && [ ! -d "$HOME/$i" ]; then
        echo "copying $folder_root/$i to ~/$i"
        cp -r "$folder_root/$i" "$HOME/$i"
    else
        echo "copying ~/$i to $folder_root/$i"
        cp -r "$HOME/$i" "$folder_root/$i"
    fi
done

