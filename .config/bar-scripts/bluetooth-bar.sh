#!/usr/bin/dash

device='6C:B1:33:8F:A0:E1'

command -v bluetoothctl >/dev/null 2>&1 || notify-send -a "${0##*/}" 'bluetooth error' 'Error, please install bluez-utils or whatever to get `bluetoothctl` command'

togglefunc() {
    case "$(bluetoothctl info "$device" | grep -oP '\s*Connected: \K.*$')" in
    'yes')
        bluetoothctl disconnect "$device"
        ;;
    'no')
        bluetoothctl connect "$device"
        ;;
    *)
        notify-send 'Bluetooth error' "Device '$device' not found!"
        ;;
    esac
}

guifunc() {
    blueman-manager
    killall blueman-applet
}

case "${1:-}" in
'--toggle')
    togglefunc
    ;;
'--manager')
    guifunc
    ;;
*)
    echo '--toggle or --status'
    ;;
esac
