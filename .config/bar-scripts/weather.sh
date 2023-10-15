#!/usr/bin/dash
case "${info:=$(curl -sf 'v2n.wttr.in?format=%c%t' | sed -E -e 's/F| //g' -e 's/\+/ /g')}" in *Sorry*) echo ' !' ;; Unknown*) echo ' ?' ;; *) echo "${info:-⚠}" ;; esac
