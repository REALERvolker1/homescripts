#!/usr/bin/dash

i='-1'
while [ -z "${display:-}" ]; do
    i=$((i + 1))
    [ ! -S "/tmp/.X11-unix/X${i}" ] && display=":${i}"
done
echo "$display"
