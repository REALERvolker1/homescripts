#!/usr/bin/bash
# a startx implementation, by vlk
# intended to be interchangeable with Fedora's startx
# shellcheck disable=SC1091 disable=SC1090

debug_mode=''
my_tty="$(tty)"
if [ "$TERM" != 'linux' ] && [ -z "${debug_mode:-}" ]; then
    case "${my_tty:-}" in
    '/dev/tty'*)
        true
        ;;
    *)
        echo "Error, you must be in a real tty! '$(tty)' does not count!"
        debug_mode=1
        ;;
    esac
fi

if [ -f "${XSERVERRC:-$HOME/.xserverrc}" ]; then
    xserver_bin="${XSERVERRC:-$HOME/.xserverrc}"
else
    xserver_bin=/usr/bin/Xorg
fi

if [ -f "${XINITRC:-$HOME/.xinitrc}" ]; then
    xclient_bin="$XINITRC"
else
    xclient_bin="$(
        oldifs="$IFS"
        IFS=':'
        for i in $XDG_DATA_DIRS; do
            [ ! -d "$i/xsessions" ] && continue
            # grab an X session automatically from a desktop session
            for j in "$i/xsessions"/*'.desktop'; do
                [ ! -f "$j" ] && continue
                my_exec="$(grep -oP '^Exec=\K.*' "$j")"
                if command -v "${my_exec%% *}" &>/dev/null; then
                    echo "${my_exec%% *}"
                    break
                fi
            done
        done
        IFS="$oldifs"
    )"
    if [ -z "${xclient_bin:-}" ]; then
        if [ -x '/etc/X11/xinit' ]; then
            xclient_bin='/etc/X11/xinit'
        else
            echo "Error, no X client bin"
            exit 3
        fi
    fi
fi

# determine unused display
i=0
while true; do
    [ -e "/tmp/.X${i}-lock" ] ||
        [ -S "/tmp/.X11-unix/X${i}" ] ||
        grep -q "/tmp/.X11-unix/X${i}" "/proc/net/unix" ||
        break
    i=$((i + 1))
done
display=":${i}"
echo "determined display $display"

# determine paths to stuff
xsessionfolder="${XDG_RUNTIME_DIR:-/tmp}/xorg-$display"
export XAUTHORITY="$xsessionfolder/Xauthority"
ERRFILE="$xsessionfolder/xsession-errors"

if [ -z "$debug_mode" ]; then
    mkdir "$xsessionfolder"
    touch -- "$XAUTHORITY"
    touch -- "$ERRFILE"
    original_stty="$(stty --save)"
fi
# Fedora specific mod to make X run as non root
export XORG_RUN_AS_USER_OK=1

declare -a xauth_args xinit_args

xauth_args+=(
    "add"
    "$display"
    'MIT-MAGIC-COOKIE-1'
    "$(mcookie)"
)

xinit_args+=(
    "$xclient_bin" # client, clientargs, --, server, display, serverargs
    "--"
    "$xserver_bin"
    "$display"
    "vt${my_tty##*[!0-9]}"
    "-keeptty"
    "-noreset"
    "-auth"
    "$XAUTHORITY"
)

_cleanup() {
    xauth remove "$display"
    rm -r "$xsessionfolder"
    deallocvt
    stty "$original_stty"
}

if [ -n "${debug_mode:-}" ]; then
    echo xauth "${xauth_args[@]}"

else
    xauth "${xauth_args[@]}"
fi
if [ -n "${debug_mode:-}" ]; then
    echo xinit "${xinit_args[@]}"
    exit 0
fi

export XDG_SESSION_TYPE=x11

xinit "${xinit_args[@]}" >"$ERRFILE"

server=$!
wait "$server"
xauth remove "$display"
rm -r "$xsessionfolder"
deallocvt
stty "$original_stty"
# retval=$?
# # _cleanup "$display" "$xsessionfolder" "$original_stty"
# exit "$retval"
