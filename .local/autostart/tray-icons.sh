#!/usr/bin/bash

pgrep nm-applet &>/dev/null || nm-applet &

pgrep firewall-applet &>/dev/null || (
    sleep 5
    exec firewall-applet
)

wait
