#!/usr/bin/dash
# mini startx, by vlk
# buncha shit stolen from https://github.com/Earnestly/sx
# shellcheck disable=SC2064
cleanup() {
    if [ "$server" ] && kill -0 "$server" 2> /dev/null; then
        kill "$server"
        wait "$server"
        xorg=$?
    fi
    if ! stty "$stty"; then
        stty sane
    fi
    xauth remove :"$tty"
}

stty=$(stty -g)
tty=$(tty)
tty="${tty#/dev/tty}"

export XORG_RUN_AS_USER_OK=1 # Fedora-specific tweak stolen from startx
export XINITRC="${XINITRC:-$HOME/.xinitrc}"
export XAUTHORITY="${XAUTHORITY:-$XDG_RUNTIME_DIR/Xauthority}"
touch -- "$XAUTHORITY"

trap 'cleanup; exit "${xorg:-0}"' EXIT
for signal in HUP INT QUIT TERM; do
    trap "cleanup; trap - $signal EXIT; kill -s $signal $$" "$signal"
done
trap 'DISPLAY=:$tty "${@:-$XINITRC}" & wait "$!"' USR1

xauth add :"$tty" MIT-MAGIC-COOKIE-1 "$(od -An -N16 -tx /dev/urandom | tr -d ' ')"
(trap '' USR1 && exec Xorg :"$tty" vt"$tty" -keeptty -noreset -auth "$XAUTHORITY") &
server=$!
wait "$server"
