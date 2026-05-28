#!/usr/bin/env dash
set -eu

if [ -z "${QDRANT_STORAGE-}" ]; then
    QDRANT_STORAGE="${XDG_STATE_HOME:-$HOME/.local/state}/qdrant_storage"
    mkdir -p "$QDRANT_STORAGE"
fi

exec podman run -p 6333:6333 -p 6334:6334 -v "$QDRANT_STORAGE:/qdrant/storage:z" qdrant/qdrant
