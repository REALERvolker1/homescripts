#!/usr/bin/env /bash
# a script by vlk to automate building required rust dependencies

if ! command -v cargo &>/dev/null; then
    echo "CRITICAL ERROR! Required dependency 'cargo' not found!" | tee /dev/stderr
    exit 1
fi

buildcfg() {
    cd "$1" || return 1
    cargo build --release
    cd "$RUSTCFG_DIR" || return 1
}

RUSTCFG_DIR="${XDG_CONFIG_HOME:=$HOME/.config}/rustcfg"

declare -a errors=()
for i in "$RUSTCFG_DIR"/*; do
    [[ "$i" == *"old" ]] && continue
    buildcfg "$i" || errors+=("$i")
done

if ((${#errors[@]})); then
    printf '%s\n' \
        "There were one or more errors building required rust packages" \
        "${errors[@]}"
    exit 1
fi
