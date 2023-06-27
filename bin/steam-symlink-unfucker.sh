#!/usr/bin/zsh
#vlk script
# Steam is the only flatpak app I have that just cannot handle symlinked or bind-mounted directories!
setopt NULL_GLOB

steamdir="$HOME/.var/app/com.valvesoftware.Steam/.config"
targetdir="${XDG_CONFIG_HOME:-$HOME/.config}"

if [ ! -d "$steamdir" ]; then
    echo "Error, steamdir '$steamdir' does not exist!"
    exit 1
fi

cd "$steamdir" || exit 1

copyfunc () {
    for i in "$steamdir"/*(@); do
        [ -z "$i" ] || [ ! -h "$i" ] && continue
        target="$(realpath "$targetdir/${i##*/}")"
        [ -z "$target" ] || [ ! -e "$target" ] && continue
        echo "$target"
        rm "$i"
        cp -r "$target" "$steamdir"
    done
}

rmfunc () {
    rm "$steamdir"/*(@) &>/dev/null && echo "removed symlinks"
}


while true; do
    rmfunc
    inotifywait -qe create "$steamdir"
done
