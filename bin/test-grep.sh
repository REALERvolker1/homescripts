#!/usr/bin/zsh

( true "${(j:\n:)path}" ) 2>/dev/null || exit 77
