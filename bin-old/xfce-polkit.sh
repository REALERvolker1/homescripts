#!/bin/sh

for i in \
    '/usr/libexec/xfce-polkit' \
    '/usr/lib/xfce-polkit/xfce-polkit'; do
    [ -x "$i" ] && exec "$i"
done

echo "Error, could not find xfce-polkit! (is it installed?)"
