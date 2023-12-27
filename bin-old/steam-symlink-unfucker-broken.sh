#!/usr/bin/dash

for i in $(pgrep 'steam-symlink-u'); do
    [ "$i" = "$$" ] && continue
    kill "$i"
done

steamdir="$HOME/.var/app/com.valvesoftware.Steam/.config"

__fileop() {
    if [ -L "$1" ]; then
        rm "$1"
        echo "removed $1"
    fi
}

for i in "$steamdir"/*; do
    __fileop "$i"
done

while true; do
    file="$steamdir/$(inotifywait -qe create "$steamdir" | grep -oP "$steamdir/ CREATE \K.*")"
    __fileop "$file"
done
