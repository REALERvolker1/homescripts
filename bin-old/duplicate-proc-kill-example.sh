#!/usr/bin/dash

MY_NAME="${0##*/}"
MY_ID="$$"
others="$(pidof -x "$MY_NAME")"
for i in $others; do
    if [ "$i" -ne "$MY_ID" ]; then
        if kill "$i"; then
            echo "killed duplicate instance of $MY_NAME ($i)"
        else
            echo "failed to kill duplicate instance of $MY_NAME ($i)"
        fi
    fi
done

