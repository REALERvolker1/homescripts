#!/usr/bin/dash
info="$(curl -s 'v2n.wttr.in?format=%c%t' | sed 's/ //g ; s/+/ / ; s/F//;s/ /  /g ; s/Unknown.*/ ?/')"
case "$info" in 'Sorry'*) exit 1 ;; *) echo "$info" ;; esac
