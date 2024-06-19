#!/usr/bin/env zsh
emulate -LR zsh -euo pipefail || exit 3

bgs=("$XDG_DATA_HOME/backgrounds/vlkbg"/*(.))
hsetroot -cover $bgs[$((1 + (RANDOM % ($#bgs - 1))))]
