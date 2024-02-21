#!/usr/bin/bash
set -eu

TEST_DIR="$PWD/test"
BIN="$PWD/target/release/better-rm"
if [[ ! -x "$BIN" ]]; then
    cargo build --release
fi

mkdir "$TEST_DIR"

touch "$TEST_DIR"/file.txt
mkdir "$TEST_DIR"/directory
mkfifo "$TEST_DIR"/directory/fifo.fifo
mkdir "$TEST_DIR"/directory/another
touch "$TEST_DIR"/directory/hello.md

echo "Created testdir at '$TEST_DIR'
Running ${BIN##*/}"

"$BIN" "$TEST_DIR"/*

echo "
Removal finished, removing test dir
"

"$BIN" "$TEST_DIR"

echo "Test completed"
