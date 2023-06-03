#!/usr/bin/bash

trap "echo 'Goodbye :)'; exit" SIGINT

for i in $(ps -eo pid,args | grep 'kitty --class=__scratchpad__' | grep -v 'grep' | cut -d ' ' -f 3); do
    kill "$i"
done

while true; do
    kitty --class='__scratchpad__'
    echo "Restarting scratchpad terminal"
done

