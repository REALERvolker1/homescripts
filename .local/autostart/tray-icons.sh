#!/usr/bin/zsh

pgrep nm-applet &>/dev/null || nm-applet &!

pgrep firewall-applet &>/dev/null || (
    sleep 5
    firewall-applet
) &!

