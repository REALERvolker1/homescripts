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
        *:"$NORATEREDUCE":*)
            i_msg="$i_msg -- dGPU-connected"
            ;;
        *)
            i_msg="$i_msg -- iGPU-connected"
            rate=60
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
case "$(cat /sys/class/power_supply/ACAD/online)" in
0) rate="$LORATE" ;;
*) rate="$HIRATE" ;;
esac

args="xrandr --output '$PRIMARY' --primary --mode '$RES' --rate '$rate' $args"

echo "sh -c \"$args\""
case "${1:-}" in
'--dry-run')
    echo "dry run -- command not run"
    ;;
'')
    sh -c "$args"
    # if pgrep 'picom' >/dev/null; then
    #     killall picom
    #     picom &
    # fi
    ;;
*)
    echo "${0##*/} --dry-run to dry-run, without args makes it run"
    exit 0
    ;;
esac
