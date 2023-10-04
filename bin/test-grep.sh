#!/usr/bin/bash

sh -c "while true; do nvidia-smi >/dev/null; sleep 5; done" &
thatpid="$!"

sleep 10
kill "$thatpid"

wait
