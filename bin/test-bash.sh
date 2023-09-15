#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

declare -A hello

hello[foo]='foof'
hello[bar]='barb'

for i in "${!hello[@]}"; do
    echo "hello[$i]=${hello[$i]}"
done

for i in "${!hello[@]}"; do
    declare "hello[$i]=dd${hello[$i]}dd"
done

for i in "${!hello[@]}"; do
    echo "hello[$i]=${hello[$i]}"
done
