#!/usr/bin/env zsh

typeset -a cargs=(-Wall -fuse-ld=mold -march=native -mtune=native)

if [[ $1 == '--debug' ]]; then
    cargs+=(-O0 -g)
else
    cargs+=(-Ofast -flto=full)
fi

clang $cargs ./**/*.c(.) -o ${PWD##*/}
