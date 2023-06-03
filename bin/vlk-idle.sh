#!/usr/bin/bash

LOCKSCREEN="${VLK_LOCKSCREEN:-vlkexec --lock 1}"

xss-lock -l "$LOCKSCREEN" &

xidlehook\
    --not-when-audio \
    --not-when-fullscreen \
    --detect-sleep \
    --timer 120 'light -S 20' 'light -I' \
    --timer 300 "$LOCKSCREEN" 'light -I'

wait
