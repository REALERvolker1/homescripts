#!/usr/bin/bash

( true "${(j:\n:)path}" ) 2>/dev/null || exit 77
