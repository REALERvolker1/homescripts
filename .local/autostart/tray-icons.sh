#!/usr/bin/env zsh

pgrep firewall-applet &>/dev/null || {
    sleep 5
    firewall-applet &!
}

pgrep nm-applet &>/dev/null || nm-applet &!

