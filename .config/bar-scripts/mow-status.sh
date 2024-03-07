#!/usr/bin/env dash

battery="$(mow report battery)"

state="${battery#*\(}"

case "${state%\)*}" in
'charging')
    echo "󰍿 ${battery%%%*}%"
    ;;
'ful'*)
    echo "󰍿"
    ;;
*'sleep'*)
    echo "󰍾"
    ;;
'Error'*)
    echo
    ;;
*)
    echo "󰍽 $battery"
    ;;
esac
