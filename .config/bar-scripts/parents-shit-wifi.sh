#!/usr/bin/env dash

if ping -c 1 'www.crates.io' >/dev/null 2>&1; then
    echo
else
    echo "💩 wifi again"
fi
