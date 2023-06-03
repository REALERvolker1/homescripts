#!/usr/bin/dash

xlayoutdisplay
if [ "$(xrandr | grep -c ' connected')" -gt 1 ]; then
    sleep 5
    #vlkbg
fi
