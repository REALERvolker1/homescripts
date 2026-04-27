#!/usr/bin/env bash
set -euo pipefail

# email: Your real email (duh)
# password: zxcv

declare -a uvargs=()

export DATA_DIR="$XDG_DATA_HOME/open_webui"
export WEBUI_SECRET_KEY='clka/b3HfwieVaya'
export RAG_SYSTEM_CONTEXT=True
export USE_CUDA=True

# export SAFE_MODE=True

# export RAG_EMBEDDING_CONTENT_PREFIX='search_document: '
export RAG_EMBEDDING_QUERY_PREFIX='search_query: '

export RUSTFLAGS='-Ctarget-cpu=native'
# export UV_SYSTEM_PYTHON=1

# echo 'ddgs==9.11.3' >"$OVERRIDES_FILE"
declare -a overrides=(
    # 'arrow @ git+https://github.com/arrow-py/arrow'
)

if ((${#overrides[@]})); then
    if [[ -z "${OVERRIDES_FILE:-}" ]]; then
        export OVERRIDES_FILE="${XDG_RUNTIME_DIR:-/tmp}/open_webui_override_requirements.txt"
    fi

    printf '%s\n' "${overrides[@]}" >"$OVERRIDES_FILE"
    uvargs+=(--overrides "$OVERRIDES_FILE")
fi

if ((${UV_SYSTEM_PYTHON:-0})); then
    uvargs+=(--no-managed-python)
else
    uvargs+=(--python '3.12')
fi

exec uv tool run \
    --link-mode symlink \
    --torch-backend auto \
    --compile-bytecode \
    "${uvargs[@]}" \
    "$@" \
    open-webui@latest \
    serve
