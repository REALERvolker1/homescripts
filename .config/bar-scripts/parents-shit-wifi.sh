#!/usr/bin/bash

if ping -c 1 'www.crates.io' &> /dev/null ; then
    echo
else
    echo "💩 wifi again"
fi

