#!/usr/bin/env bash
set -euo pipefail
IFS=$'\t\n'

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"

if [[ -f "$PWD/.clang-format" ]]; then
    exec "$CLANG_FORMAT" "$@"
    exit "$?"
fi

if [[ -z "${CLANG_FORMAT_FILE:=}" ]]; then
: "${XDG_CONFIG_HOME:=$HOME/.config}"


for i in \
    "$HOME/.clang-format" \
    "$XDG_CONFIG_HOME/clangd/"{.clang-format,format}{.yaml,} \
    "$XDG_CONFIG_HOME/clang-format/"{.clang-format,format,config}{.yaml,}; do
    if [[ -f "$i" ]]; then
        CLANG_FORMAT_FILE="$i"
        break
    fi
done

fi

if [[ -n "$CLANG_FORMAT_FILE" ]]; then
    ln -s "$CLANG_FORMAT_FILE" "$PWD/.clang-format"
    exit # TODO FINISH
fi


"$CLANG_FORMAT" "$@"
fmt_exit="$?"

if [[ -l "$PWD/."
