#!/usr/bin/bash
# mini startx, by vlk
# buncha shit stolen from https://github.com/Earnestly/sx
# shellcheck disable=SC2064

_panic() {
    printf '%s\n' "$@" >&2
    exit 1
}

# support custom X server implementations, default to the best*
STX_XSERVER="${STX_XSERVER:-Xorg}"
[[ -e ${XINITRC-} ]] || XINITRC="$HOME/.xinitrc"

# Check for dependencies
declare -a faildeps=()
for i in stty tty xauth "$STX_XSERVER" deallocvt mcookie; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
if ((${#faildeps[@]})); then
    _panic "Error, missing dependencies:" "${faildeps[@]}"
fi

: "${TTY:=$(tty)}"
OLDSTTY=$(stty -g)

# Fedora-specific tweak to force startx to run as the current user because selinux I think
[[ -e /etc/redhat-release ]] && export XORG_RUN_AS_USER_OK=1

# set the Xauthority file in an XDG-compliant manner
export XAUTHORITY="${XAUTHORITY:-$XDG_RUNTIME_DIR/Xauthority}"

# make sure we're in a real vtty and not some sort of Xterm
[[ ${TERM:-Undefined} != 'linux' && ${TTY-} != '/dev/tty'* ]] &&
    _panic "Error, you must be in a real vtty!" "Terminal '${TERM-}' and '$TTY' do not count!"

# Determine which commands to run with the X server
declare -a EXEC_COMMAND
if (($#)); then
    # refuse to run without a valid binary. This should make --help work while keeping code simple
    if [[ -x $1 ]] || command -v "$1" &>/dev/null; then
        EXEC_COMMAND=("$@")
    else
        me="${0##*/}"
        echo "\
Error, invalid command '$1'!

Usage: $me [command] --arg1 --arg2
Run a command with the X server running. It must be a valid executable

If no command is specified, $me will use your xinitrc. (Currently: $XINITRC)

Example: '$me i3' will start i3 window manager with the X server running." >&2
        exit 1
    fi
elif [[ -x $XINITRC ]]; then
    EXEC_COMMAND=("$XINITRC")
else
    _panic "Error, couldn't find a suitable xinitrc!"
fi

# find an unused DISPLAY
declare -i count=0
while [[ -e /tmp/.X${count}-lock ]]; do
    count=$((count + 1))
done
display=":$count"
vt="${TTY##*[^[:digit:]]}"

# Cleanup function.  Kills the server, removes Xauthority, deallocates unused vtty
cleanup() {
    if [[ ${server-} && -e /proc/$server ]]; then
        kill "$server"
        wait "$server"
        x_retval=$?
    fi
    stty "$OLDSTTY" || stty sane
    xauth remove "$display"
    deallocvt "$vt"
}
cleanup::exit() {
    cleanup
    exit "${x_retval:-0}"
}
cleanup::alt() {
    local signal="${1:?Error, no signal given}"
    cleanup
    # remove the Exit signal handler, as these signals are a little different
    trap - "$signal" EXIT
    # this is not a cry for help, it is necessary to propagate the signal
    kill -s "$signal" "$$"
}

exec::xserver() {
    trap '' USR1 && exec "$STX_XSERVER" "$display" vt"$vt" -keeptty -noreset -auth "$XAUTHORITY"
}

exec::desktop() {
    DISPLAY=$display "${EXEC_COMMAND[@]}" &
    wait "$!"
}

# Create Xauthority and authenticate the X server
: >"$XAUTHORITY"
xauth add "$display" MIT-MAGIC-COOKIE-1 "$(mcookie)"

# cleanup on exit
trap 'cleanup::exit' EXIT

# signals we want to propagate to this script
for i in HUP INT QUIT TERM; do
    trap "cleanup::alt $i" "$i"
done

# X servers send SIGUSR1 when they are ready to receive connections.
# Yes, async bash is this janky.
trap 'exec::desktop' USR1

# start the X server and wait for it to exit
exec::xserver &
server=$!
wait "$server"
