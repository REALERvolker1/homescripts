#!/bin/sh

BATTERY="/org/freedesktop/UPower/devices/battery_BAT1"
AC="/org/freedesktop/UPower/devices/line_power_ACAD"

current_ac=""
current_bat=""
current_perc=""
current_state=""
current_w=""

upower_parse () {
    local device=$(echo "$1" | grep -o '/.*$')
    local data=$(upower -i "$device" | sed 's/$/\\n/g')
    if [[ "$device" == "$BATTERY" ]]; then
        local percentage=$(echo -e $data | grep 'percentage' | xargs | cut -d ' ' -f 2 | sed 's/%//')
        local state=$(echo -e $data | grep 'state' | xargs | cut -d ' ' -f 2)
        local energy=$(printf "%0.2f" $(echo -e $data | grep 'energy-rate' | xargs | cut -d ' ' -f 2))

        if [[ $percentage -gt "80" ]]; then
            current_bat=' '
        elif [[ $percentage -gt "60" ]]; then
            current_bat=' '
        elif [[ $percentage -gt "40" ]]; then
            current_bat=' '
        elif [[ $percentage -gt "20" ]]; then
            current_bat=' '
        elif [[ $percentage -gt "0" ]]; then
            current_bat=' '
        fi

        if [ $(echo "$energy < 1" | bc -l) -eq 1 ]; then
            energy=""
        else
            energy=" $energy W"
        fi


        current_perc="$percentage%"
        current_state="$state"
        current_w="$energy"
    elif [[ "$device" == "$AC" ]]; then
        local online=$(echo -e $data | grep 'online' | xargs | cut -d ' ' -f 2)
        #current_ac="$online"
        if [[ $online == "yes" ]]; then
            current_ac="󱐋"
        elif [[ $online == "no" ]]; then
            current_ac=""
        else
            current_ac="?"
        fi
    fi
    #echo "$current_ac $current_state $current_bat $current_w"
    echo "{\"icon\":\"$current_ac$current_bat \",\"state\":\"$current_state\",\"percentage\":\"$current_perc\",\"power\":\"$current_w\"}"
}

upower_parse $BATTERY
upower_parse $AC

upower -m | while read line; do upower_parse "$line"; done
# [ -n $device ] && echo 'na' && exit
