#!/bin/sh
set -eu
IFS="$(printf '\n\t')"

outfile="./${PWD##*/}"
srcfiles="$(find . -maxdepth 3 -name '*.c')"

printf '+ %s\n' $srcfiles

clang -Wall -O3 -o "$outfile" "$@" $srcfiles

printf 'Built %s\n\n' "$outfile"
