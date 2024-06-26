#!/usr/bin/bash

for i in mplab_ide nmcli; do
    command -v "$i" || {
        echo "Error, missing command: '$i'"
        exit 1
    }
done

nmcli n off

(
    sleep 10
    nmcli n on
) &

disown

exec mplab_ide
