#!/usr/bin/dash
curl -s 'v2n.wttr.in?format=%c%t' | sed 's/ //g ; s/+/ / ; s/F//;s/ /  /g ; s/Unknown.*/ ?/'
