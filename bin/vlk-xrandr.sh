#!/usr/bin/dash
# xrandr script so I don't ever have to use xlayoutdisplay again
set -eu
IFS='
'

# name of the monitor
PRIMARY='eDP-1'
HIRATE=144
LORATE=60
RES='1920x1080'

# --left-of, --right-of, --above, --below
RELATIVE_POS='--left-of'

# my hardware has an interesting quirk where if my external monitor is
# plugged into my dedicated GPU port, it does not reduce the refresh rate
# of my primary monitor. This should be impossible, as xorg sees both
# monitors as a single screen, but I'm not complaining
# Less fortunate people can just set it to '' I think
NORATEREDUCE=':HDMI-1-0:DP-1-0:'

# state monitoring for monitor mode
STATEPATH="${XDG_RUNTIME_DIR:-/tmp}/vlk-xrandr-state"

dry=false
monitor=false
case "${1:-}" in
'--dry-run')
    echo "dry run -- command will not run"
    dry=true
    ;;
'--monitor')
    if command -v xev >/dev/null; then
        echo "[${0##*/}] monitoring for 'XRROutputChangeNotifyEvent'"
        monitor=true
    else
        echo "Error, dependency 'xev' not found!"
        exit 1
    fi
    ;;
'')
    true
    ;;
*)
    printf '%s\n' "${0##*/} --args" \
        '<no args>   run as usual' \
        '--dry-run   print the command but do not run' \
        '' \
        "Edit the script at '$0' to specify monitor details"
    exit 0
    ;;
esac

_run() {
    rate="$HIRATE"
    has_primary=false
    # args="xrandr --output '$PRIMARY' --primary --auto"
    args=''
    previous="$PRIMARY"

    for i in $(xrandr | grep -oP '^.*(?= connected)'); do
        i_msg="detected monitor $i"
        case "$i" in
        "$PRIMARY")
            i_msg="$i_msg -- \$PRIMARY"
            # make sure we actually have the primary monitor here
            has_primary=true
            ;;
        *)
            case :"$i": in
            *"$NORATEREDUCE"*)
                i_msg="$i_msg -- dGPU-connected"
                ;;
            *)
                i_msg="$i_msg -- iGPU-connected"
                rate="$LORATE"
                ;;
            esac
            args="$args --output '$i' --auto $RELATIVE_POS '$previous'"
            previous="$i"
            ;;
        esac
        echo "$i_msg"
    done

    if ! $has_primary; then
        echo "Error, \$PRIMARY monitor '$PRIMARY' not detected!"
        exit 1
    fi

    # forcibly switch to the lower refresh rate if not plugged in
    [ "$(cat /sys/class/power_supply/ACAD/online)" -eq 0 ] && rate="$LORATE"

    # temporary stopgap
    args="xrandr --output '$PRIMARY' --primary --mode '$RES' --rate '$HIRATE' $args"
    #args="xrandr --output '$PRIMARY' --primary --mode '$RES' --rate '$rate' $args"

    if ! $dry; then
        if ! sh -c "$args"; then
            echo "Error, failed to run command"
        fi
        echo "sh -c \"$args\""
    fi
    (
        command -v vlkbg.sh &>/dev/null && vlkbg.sh &
    )
}

if $monitor; then
    touch -- "$STATEPATH" && echo monitoring -- using "$STATEPATH"
    _run
    xev -root -event randr | grep --line-buffered 'XRROutputChangeNotifyEvent' | while read -r line; do
        if [ "$args" != "$(cat "$STATEPATH")" ]; then
            _run
            echo "$args" >"$STATEPATH"
        fi
    done
else
    _run
fi
