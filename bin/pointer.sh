#!/usr/bin/dash
# script by vlk
# vim:foldmethod=marker:ft=sh

set -eu
get_status_icon() {
    case "$(cat "$TOUCHPAD_STATUS")" in
    1)
        echo "󰟸"
        ;;
    0)
        echo "󰤳"
        ;;
    *)
        echo "󰟸 ?"
        ;;
    esac
}

touchpad_operation() {
    local operation="${1:?Error, please select a state for the touchpad}"
    local fs_state
    case "$operation" in
    'enable')
        fs_state=1
        ;;
    'disable')
        fs_state=0
        ;;
    esac
    case "$PLATFORM" in
    'x11')
        if xinput "$operation" "$touchpad_name"; then
            printf '%s' "$fs_state" >"$TOUCHPAD_STATUS"
            printf "Touchpad %s\n" "$1"
        fi
        ;;
    'hyprland')
        if [ "$(hyprctl keyword device:"$touchpad_name":enabled "$fs_state")" = 'ok' ]; then
            printf '%s' "$fs_state" >"$TOUCHPAD_STATUS" && printf "Touchpad %s\n" "$operation"
        fi
        hyprctl keyword device:"$touchpad_name":natural_scroll true >/dev/null
        ;;
    esac
}

normalize_input() {
    local inputs
    case "$PLATFORM" in
    'x11') inputs="$(xinput)" ;;
    'hyprland') inputs="$(hyprctl devices)" ;;
    esac

    if echo "$inputs" | grep -Ev "$egrep_mouse_blacklist" | grep -qE "$egrep_mouse_name"; then
        echo 'mouse detected. Disabling trackpad'
        touchpad_operation disable
    else
        echo 'no mouse detected. Enabling trackpad'
        touchpad_operation enable
    fi
}

TOUCHPAD_STATUS="$XDG_RUNTIME_DIR/touchpad-statusfile"
if [ ! -f "$TOUCHPAD_STATUS" ]; then
    touch "$TOUCHPAD_STATUS"
fi

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    touchpad_name='ASUP1205:00 093A:2003 Touchpad'
    wireless_name='Glorious Model O Wireless'
    wired_name='Glorious Model O'
    egrep_mouse_name='(Glorious Model O Wireless|Glorious Model O)  '
    egrep_mouse_blacklist="(\
${wired_name} Keyboard|\
${wireless_name} Keyboard|\
${wireless_name} System Control|\
${wireless_name} Consumer Control\
)"
    PLATFORM='x11'
elif [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    touchpad_name='asup1205:00-093a:2003-touchpad'
    wireless_name='glorious-model-o-wireless'
    wired_name='glorious-model-o'
    egrep_mouse_name='(glorious-model-o-wireless|glorious-model-o)'
    egrep_mouse_blacklist="(\
${wired_name}-keyboard|\
${wired_name}-system-control|\
${wired_name}-consumer-control|\
${wireless_name}-keyboard|\
${wireless_name}-consumer-control|\
${wireless_name}-system-control\
)"
    PLATFORM='hyprland'
fi

sel="${1:-}"

case "$sel" in
-i)
    get_status_icon
    ;;
-m)
    while true; do
        get_status_icon
        inotifywait -qe close_write "$TOUCHPAD_STATUS" >/dev/null
    done
    ;;
-te)
    touchpad_operation enable
    ;;
-td)
    touchpad_operation disable
    ;;
-t)
    case "$(cat "$TOUCHPAD_STATUS")" in
    1)
        touchpad_operation disable
        ;;
    0)
        touchpad_operation enable
        ;;
    *)
        printf 'Error, touchpad is not normalized yet. Normalizing...\n'
        normalize_input
        ;;
    esac
    ;;
-n)
    normalize_input
    ;;
*)
    printf '%s --option

-i\tget statusline icon
-m\tmonitor statusline icon
-te\tenable touchpad
-td\tdisable touchpad
-t\ttoggle touchpad
-n\tnormalize touchpad (disable on mouse)
' "${0##*/}"
    exit 1
    ;;
esac

# Query device {{{

# xinput | while read line; do [[ $line == *"ASUP1205:00 093A:2003 Touchpad"* ]] && line="${${line##*id=}%%[0-9]* }" && echo "==$line=="; done

# swaymsg input type:touchpad events <enabled|disabled|disabled_on_external_mouse|toggle>

# xorg.conf settings {{{
# /etc/X11/xorg.conf.d
#   30-mouse.conf
#       Section "InputClass"
#           Identifier "Mouse Fix"
#           MatchIsPointer "on"
#           Option "AccelProfile" "flat"
#           Option "AccelSpeed" "0"
#       EndSection
#
#   31-touchpad.conf
#       Section "InputClass"
#           Identifier "Touchpad options"
#           MatchIsTouchpad "on"
#           Option "Tapping" "on"
#           Option "NaturalScrolling" "on"
#       EndSection
# }}}
