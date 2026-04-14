#!/usr/bin/env bash

# email: Your real email (duh)
# password: zxcv

export DATA_DIR="$XDG_DATA_HOME/open_webui"
export WEBUI_SECRET_KEY='clka/b3HfwieVaya'

if [[ -z "${OVERRIDES_FILE:-}" ]]; then
    export OVERRIDES_FILE="${XDG_RUNTIME_DIR:-/tmp}/open_webui_override_requirements.txt"
fi

echo 'ddgs==9.11.3' >"$OVERRIDES_FILE"

exec uvx \
    --python 3.12 \
    --overrides "$OVERRIDES_FILE" \
    "$@" \
    open-webui@latest \
    serve
