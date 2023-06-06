#!/bin/sh

get_volume () {
    #local volume="$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%')"
    #left=$(echo "$volume" | head -n 1)
    #right=$(echo "$volume" | tail -n 1)
    local volume=$(echo `pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | sed 's/%//g'`)
    local volume_short=$(echo $volume | cut -d ' ' -f 1)
    if [[ $(echo $volume | cut -d ' ' -f 2) == $volume_short ]]; then
        echo "$volume_short"
    else
        echo "L:$volume_short R:$(echo $volume | cut -d ' ' -f 2)"
    fi
    #echo $info | jq '.[].volume | .["front-left"].value_percent, .["front-right"].value_percent' | grep -o '[0-9, ]*'
}

get_eww_volume () {
    # 󰋋󰟎󰥰
    #local volume=$(pactl get-sink-volume @DEFAULT_SINK@)
    #local muted=$(pactl get-sink-mute @DEFAULT_SINK@)
    #echo "$volume"
    local current=$(pactl get-default-sink)
    local info=$(pactl --format='json' list sinks | jq -M "[.[] | select(.name == \"$current\")]")

    local volume=$(get_volume)
    local muted=$(echo $info | jq '.[] | .mute')
    local mic=$(pactl get-source-mute @DEFAULT_SOURCE@ | sed 's/^Mute: //')
    
    if [[ $muted == "true" ]]; then
        local icon="󰟎 "
    else
        local icon="󰋋 "
    fi
    if [[ $mic == "no" ]]; then
        local micon="󰍭 "
    elif [[ $mic == "yes" ]]; then
        local micon="󰍬 "
    else
        local micon="󰍬? "
    fi

    if echo $info | grep 'api.bluez5.address' > /dev/null; then
        local bluetooth="true"
        local icon="󰂯$icon"
        local bluetooth_info=$(bluetoothctl info | sed 's/$/\\n/g')
        local name=$(echo -e $bluetooth_info | grep '^[[:space:]]Name' | sed 's/^[[:space:]]Name: //g')
    else
        local bluetooth="false"
        local name=$(echo $info | jq '.[] | .description')
    fi

    echo "{'name':'$name','icon':'$icon','volume':'$volume','mic':'$micon'}" | sed "s/'/\"/g"
}

set_volume () {
    local volume=$(echo $1 | grep -o '[0-9]*')
    pactl set-sink-volume @DEFAULT_SINK@ "$volume%"
}

case $1 in
    "-g")
        get_volume
    ;;
    "-eww")
        get_eww_volume
    ;;
    "-m")
        pactl --format='json' subscribe | while read line; do echo $line | jq; done
    ;;
    "-s")
        set_volume $2
    ;;
esac

