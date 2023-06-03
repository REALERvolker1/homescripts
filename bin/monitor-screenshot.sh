#!/usr/bin/env bash

current_display="$(i3-msg -t get_workspaces | jq '.[] | select(.focused == true) | .output')"
echo "$current_display"
