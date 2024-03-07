#!/usr/bin/env bash

case "$(gammastep -p |& grep -Po 'Period: *\K[A-Z,a-z]+')" in
'Daytime')
    echo '' >"$XDG_RUNTIME_DIR/gammastep-hook.status"
    #busctl --user call rs.i3status /redshift rs.i3status.custom SetIcon s gammastep_off
    ;;
'Night')
    echo '󰌵' >"$XDG_RUNTIME_DIR/gammastep-hook.status"
    #busctl --user call rs.i3status /redshift rs.i3status.custom SetIcon s gammastep_on
    ;;
*)
    #echo "undefined"
    ;;
esac

# command = "cat ~/.cache/gammastep-hook.txt"
# watch_files = ["~/.cache/gammastep-hook.txt"]
# interval = 'once'
