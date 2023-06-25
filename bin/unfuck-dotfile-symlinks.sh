#!/usr/bin/bash
set -euo pipefail

symlinks=(
    "$XDG_CONFIG_HOME/Kvantum"
    "$XDG_CONFIG_HOME/fontconfig"
    "$XDG_CONFIG_HOME/MangoHud"
    "$XDG_CONFIG_HOME/gtk-2.0"
    "$XDG_CONFIG_HOME/gtk-3.0"
    "$XDG_CONFIG_HOME/gtk-4.0"
)

replacedirs () {
    local link="$1"
    local target="$2"
    local linkdate=0
    local targetdate=0
    linkdate="$(stat -c '%Y' "$link")"
    targetdate="$(stat -c '%Y' "$target")"
    if ((linkdate < targetdate)); then
        echo "replacing contents of $link with $target"
    else
        echo "replacing contents of $link with $target"
    fi
}

for link in "${symlinks[@]}"; do
    target="${link//$HOME/$HOMESCRIPTS}"
    [ ! -e "$link" ] && cp -Rf "$target" "$link" && echo "copied '$target' '$link'"
    #replacedirs "$link" "$target"
    rm -ri "$target" && cp -Rf "$link" "$target"
done

