#!/usr/bin/bash
# script by vlk
# mplab has a bug where it will freeze when you open it while connected to the internet.
# This is a workaround.

for i in mplab_ide nmcli; do
    command -v "$i" || {
        echo "Error, missing command: '$i'"
        exit 1
    }
done

nmcli n off

(
    sleep 5
    nmcli n on
) &

disown

exec mplab_ide "$@"
