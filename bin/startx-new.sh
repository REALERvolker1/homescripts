#!/usr/bin/dash
# shellcheck disable=SC2064

unset DBUS_SESSION_BUS_ADDRESS
unset SESSION_MANAGER

get_xinitrc () {
    local xrc
    if [ -n "${XINITRC:-}" ] && [ -x "${XINITRC:-}" ]; then
        xrc="$XINITRC"
    elif [ -x "${XDG_CONFIG_HOME:-$HOME/.config}/X11/xinitrc" ]; then
        xrc="${XDG_CONFIG_HOME:-$HOME/.config}/X11/xinitrc"
    elif [ -x "$HOME/.xinitrc" ]; then
        xrc="$HOME/.xinitrc"
    elif [ -x '/etc/X11/xinit/xinitrc' ]; then
        xrc='/etc/X11/xinit/xinitrc'
    else
        echo "Error finding xinitrc!"
        exit 1
    fi
    [ -n "$xrc" ] && echo "$xrc"
}

get_open_display () {
    # find a $DISPLAY that isn't being used yet
    local i=0
    while true; do
        [ -e "/tmp/.X$i-lock" ] || \
            [ -S "/tmp/.X11-unix/X$i" ] || \
            grep -q "/tmp/.X11-unix/X$i" "/proc/net/unix" || \
            break
        i=$((i + 1))
    done
    echo ":$i"
}

get_current_tty_vtarg () {
    # start X on the current TTY to fix "https://bugzilla.redhat.com/show_bug.cgi?id=806491"
    local tty
    local tty_num
    tty="$(tty)"
    if expr "$tty" : '/dev/tty[0-9][0-9]*$' > /dev/null; then
        tty_num="$(echo "$tty" | grep -oE '[0-9]+$')"
        export XORG_RUN_AS_USER_OK=1
        echo "vt$tty_num -keeptty"
    fi
}

print_help () {
    local bold
    local sgr
    bold="$(tput bold)"
    sgr="$(tput sgr0)"
    cat << EOF
Received args: '$@'
Options are:

${bold}--client=''${sgr}    start a non-default client
    default: your xinitrc (\$XINITRC or \$XDG_CONFIG_HOME/X11/xinitrc or ~/.xinitrc)
${bold}--server=''${sgr}    start a non-default server
    default: /usr/bin/X
${bold}--display=''${sgr}   manually choose an open DISPLAY
    default: automatically chosen
${bold}--vtarg=''${sgr}     manually enter vtargs
    default: automatically chosen
${bold}--xauth=''${sgr}     manually specify an Xauthority
    default: automatically chosen

Toggles:
${bold}--dry-run${sgr}      print commands executed, but do not actually do anything

Example command:
${bold}${0##*/} --client='i3 --force-xinerama -d all' --display=':69'${sgr}
EOF
    exit 1
}

arg=''
for arg in "$@"; do
    parg="${arg#*=}"
    case "$arg" in
        '--client=')
        client="$parg"
        ;;
        '--server=')
        server="$parg"
        ;;
        '--display=')
        display="$parg"
        ;;
        '--vtarg=')
        vtarg="$parg"
        ;;
        '--xauth')
        xauth="$parg"
        ;;
        '--dry-run')
        DRY_RUN=1
        ;;
        '')
        continue
        ;;
        *)
        help_print=1
        ;;
    esac
done

[ -z "${client:-}" ] && client="$(get_xinitrc)"
[ -z "${server:-}" ] && server='/usr/bin/X'
[ -z "${display:-}" ] && display="$(get_open_display)"
[ -z "${vtarg:-}" ] && vtarg="$(get_current_tty_vtarg)"
#[ -z "${xauth:-}" ] && xauth="$(get_xauthority "$display")"
[ -n "${help_print:-}" ] && print_help "$@"

unset serverargs
echo "$server" | grep -q 'vt[0-9][0-9]*$' || serverargs="$serverargs $vtarg"

# set xauthority
if [ -z "${xauth:-}" ] || [ -z "${DRY_RUN:-}" ]; then
    xauthname="Xauthority"
    sauthname="serverauth.$$"
    if [ -n "${XAUTHORITY:-}" ]; then
        authfolder="${XAUTHORITY%/*}"
        xauthname="${XAUTHORITY##*/}"
    elif [ -d "${XDG_RUNTIME_DIR}" ] && [ -n "${XDG_RUNTIME_DIR}" ]; then
        authfolder="$XDG_RUNTIME_DIR"
    elif [ -w '/tmp' ]; then
        authfolder='/tmp'
    elif [ -d "${XDG_CACHE_HOME:-$HOME/.cache}" ]; then
        authfolder="${XDG_CACHE_HOME:-$HOME/.cache}"
    else
        authfolder="$HOME"
        xauthname=".${xauthname}"
        sauthname=".${sauthname}"
    fi
    xauthfile="${authfolder}/${xauthname}"
    xserverauthfile="${authfolder}/${sauthname}"
    export XAUTHORITY="$xauthfile"

    [ -e "$xauthfile" ] && rm -f "$xauthfile"
    [ -e "$xserverauthfile" ] && rm -f "$xserverauthfile"

    cookie="$(/usr/bin/mcookie)"
    [ -z "${cookie:-}" ] && echo "Couldn't create cookie" && exit 1
    dummy=0

    # create a file with auth information for the server. ':0' is a dummy.
    if [ -n "${DRY_RUN:-}" ]; then
        echo "Dry-run: create xauth in $xserverauthfile"
    else
        xauth -q -f "$xserverauthfile" << EOF
add :$dummy . $cookie
EOF
        serverargs="$serverargs -auth $xserverauthfile"
    fi

    trap "rm -f '$xserverauthfile'" HUP INT QUIT ILL TRAP BUS TERM #KILL
    unset removelist
    # this weird non-quoted syntax was in startx before and I was too scared to change it
    if [ -z "${DRY_RUN:-}" ]; then
        for disp in "$display" "$(hostname)$display"; do
            authcookie="$(xauth list "$disp" | sed -n "s/.*${disp}[[:space:]*].*[[:space:]*]//p" 2>/dev/null)"
            if [ -z "${authcookie:-}" ]; then
                xauth -q << EOF
add $disp . $cookie
EOF
                removelist="$disp $removelist"
            else
                dummy=$((dummy + 1))
                xauth -q -f "$xserverauthfile" << EOF
add :$dummy . $authcookie
EOF
            fi
        done
    fi
fi

#echo "xinit client: $client under server $server on display $display with vtarg $vtarg and auth $xauth"

if [ -n "${DRY_RUN:-}" ]; then
    echo 'xinit' "$client" -- "$server" "$display" $serverargs
    retval=0
else
    xinit "$client" -- "$server" "$display" $serverargs
    retval=$?
    [ -n "${removelist:-}" ] && xauth remove $removelist
    [ -f "${xserverauthfile:-}" ] && rm -f "$xserverauthfile"

    deallocvt
fi

exit $retval

# xinit "$client" $clientargs -- "$server" $display $serverargs
