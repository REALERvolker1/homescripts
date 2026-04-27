#!/usr/bin/env bash
# Script to run the latest version of Debian in a temporary ephemeral podman container.
# Additionally, creates a backdoor directory on the host and mounts it into the container at /backdoor.

# Ensure we exit on any error
set -euo pipefail

# Define host directory for backdoor (using XDG_CACHE_HOME or fallback to $HOME/.cache)
HOST_BACKDOOR_DIR="${XDG_CACHE_HOME:="$HOME/.cache"}/${0%%.*}_backdoor"
# Create the directory on the host
mkdir -p "$HOST_BACKDOOR_DIR"

# Default to running an interactive shell if no command is provided
if [[ $# -eq 0 ]]; then
    set -- /bin/bash
fi

# Run the latest Debian image in an ephemeral container (removed after exit)
# Mount the host backdoor directory to /backdoor inside the container
podman run --rm -it -v "$HOST_BACKDOOR_DIR:/backdoor" docker.io/library/debian:latest "$@"