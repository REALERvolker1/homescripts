#!/usr/bin/zsh
#vlk script
# Steam is the only flatpak app I have that just cannot handle symlinked or bind-mounted directories!
setopt NULL_GLOB

for i in $(pgrep 'steam-symlink-u'); do
    [ "$i" = "$$" ] && continue
    kill "$i"
done

steamdir="$HOME/.var/app/com.valvesoftware.Steam"

if [ ! -d "$steamdir" ]; then
    echo "Error, steamdir '$steamdir' does not exist!"
    exit 1
fi

cd "$steamdir" || exit 1

while true; do
    rm "$steamdir/.config"/*(@) &>/dev/null && echo "removed config symlinks"
    # rm "$steamdir/.local/share"/*(@) &>/dev/null && echo "removed local-share symlinks"
    rm "$steamdir/"{Music,Pictures} &>/dev/null && echo "removed home symlinks"
    inotifywait -qe create "$steamdir/.config" "$steamdir/.local/share" "$steamdir"
done

wait
