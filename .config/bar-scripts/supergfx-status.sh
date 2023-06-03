#!/usr/bin/dash
# script by vlk

_get_icon () {
    case "$1" in
        '0')
            echo '󰒇'
        ;;
        '1')
            echo '󰒆'
        ;;
        '2')
            echo '󰒅'
        ;;
        '3')
            echo '󰒈'
        ;;
        '4')
            echo '󰾂'
        ;;
    esac
}

case "$(supergfxctl -S)" in
    active) _get_icon 0
    ;; suspended) _get_icon 1
    ;; off) _get_icon 2
    ;; dgpu_disabled) _get_icon 3
    ;; asus_mux_discreet) _get_icon 4
    ;;
esac

dbus-monitor --system "type='signal',interface='org.supergfxctl.Daemon',member='NotifyGfxStatus'" 2>/dev/null | while read -r line; do
    _get_icon "${line##* }"
done

