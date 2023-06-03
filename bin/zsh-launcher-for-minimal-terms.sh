#!/usr/bin/env bash

for i in "$@"; do
    key="${i%=*}"
    val="${i#*=}"
    #echo "$key = $val"
    eval "export ${key}=\"${val}\""
done

exec /usr/bin/zsh
