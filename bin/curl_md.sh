#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

curl -sSL "$@" | markdownify | prettier --parser markdown
