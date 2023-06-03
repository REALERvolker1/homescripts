#!/usr/bin/dash

device='6C:B1:33:8F:A0:E1'

togglefunc () {
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

guifunc () {
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
