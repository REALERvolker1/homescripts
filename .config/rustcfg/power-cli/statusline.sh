#!/usr/bin/env zsh
set -euo pipefail

export POWERCLI_LOCKFILE="$XDG_RUNTIME_DIR/power-module.lock"

if [[ ! -f $POWERCLI_LOCKFILE ]] {
    ${0:A:h}/daemon.sh --waybar &!
}
# notify-send "Power Module" "Running"
<$POWERCLI_LOCKFILE
