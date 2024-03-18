#!/usr/bin/zsh
#vlk script
setopt NULL_GLOB

for i in $(pgrep 'heroic-symlink-'); do
    [ "$i" = "$$" ] && continue
    kill "$i"
done

hgdir="$HOME/.var/app/com.heroicgameslauncher.hgl"

if [ ! -d "$hgdir" ]; then
    echo "Error, hgdir '$hgdir' does not exist!"
    exit 1
fi

cd "$hgdir" || exit 1

while true; do
    rm "$hgdir/.config"/*(@) &>/dev/null && echo "removed config symlinks"
    rm "$hgdir/.local/share"/*(@) &>/dev/null && echo "removed local-share symlinks"
    rm "$hgdir/"{Music,Pictures,Documents} &>/dev/null && echo "removed home symlinks"
    inotifywait -qe create "$hgdir/.config" "$hgdir/.local/share" "$hgdir"
done

wait
