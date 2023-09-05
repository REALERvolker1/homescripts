#!/usr/bin/bash

__vlkenv_data_dirs=''

oldifs="$IFS"
IFS=':'
for i in $XDG_DATA_DIRS; do
    [ ! -d "$i" ] && continue
    __vlkenv_data_dirs="$i:${__vlkenv_data_dirs}"
done
IFS="$oldifs"

echo "$__vlkenv_data_dirs"
