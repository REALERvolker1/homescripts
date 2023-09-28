#!/bin/zsh

plugin-install() {
    command -v git &>/dev/null || return 2
    [ ! -d "$ZPLUGIN_DIR" ] && mkdir -p "$ZPLUGIN_DIR"
    cd "$ZPLUGIN_DIR" &>/dev/null

    local gh='https://github.com'
    local -a zsh_plugins=(
        "$gh/romkatv/zsh-defer"
        "$gh/Aloxaf/fzf-tab"
        "$gh/zdharma-continuum/fast-syntax-highlighting"
        "$gh/zsh-users/zsh-autosuggestions"
    )
    if [[ "$(printf '%s\n' "$ZPLUGIN_DIR"/*(N))" != '' ]]; then
        local count=0
        for i in "$ZPLUGIN_DIR"*(N); do
            if [ ! -d "${i}-bak-${count}" ]; then
                # mkdir -p "${i}-bak-${count}"
                echo "${i}-bak-${count}"
                break
            else
                count=$((count + 1))
            fi
        done
        # [[ "$i"  ]]
        # mkdir -p "${ZPLUGIN_DIR}-bak"
        # mv "$ZPLUGIN_DIR/"* "${ZPLUGIN_DIR}-bak"
    fi
    local i
    for i in "${zsh_plugins[@]}"; do
        echo "$i"
    done
}

plugin_init() {
    local oldpwd="$PWD"
    local gh='https://github.com'
    local i
    local -a plugins=(
        "$gh/romkatv/zsh-defer=$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
        "$gh/Aloxaf/fzf-tab=$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
        "$gh/zdharma-continuum/fast-syntax-highlighting=$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        "$gh/zsh-users/zsh-autosuggestions=$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
    )
    local -a installed_plugins
    for i in "${plugins[@]}"; do
        if [ -f "${i#*=}" ]; then
            installed_plugins+="${i#*=}"
        elif command -v git &>/dev/null; then
            mkdir -p "$ZPLUGIN_DIR"
            cd "$ZPLUGIN_DIR" &>/dev/null
            git clone "${i%%=*}"
            if [ -f "${i#*=}" ]; then
                installed_plugins+="${i#*=}"
            fi
        fi
    done
    printf '%s\n' "${installed_plugins[@]}"
}

export ZPLUGIN_DIR="$HOME/zsh-plugins"
for i in 'Aloxaf/fzf-tab' 'zdharma-continuum/fast-syntax-highlighting' 'zsh-users/zsh-autosuggestions'; do
    filepath="$ZPLUGIN_DIR/${i#*/}/${i#*/}.plugin.zsh"
    if [ -f "$filepath" ]; then
        echo "$filepath"
    else
        giturl="https://github.com/${i}"
        if [ ! -d "$ZPLUGIN_DIR" ]; then
            if [ -e "$ZPLUGIN_DIR" ]; then
                echo "Error loading plugins -- \"$ZPLUGIN_DIR\" already exists!"
        git clone "$giturl"
        echo "$giturl"
    fi
done

lol() {
    if [ -f "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh" ]; then
        . "$ZPLUGIN_DIR/zsh-defer/zsh-defer.plugin.zsh"
    else
        get_plugins
        return
    fi
    local i
    for i in \
        "$ZPLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" \
        "$ZPLUGIN_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
        "$ZPLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
        if [ -f "$i" ] && zsh-defer "$i"
    done
}

get_plugins() {
    if [ ! -d "$ZPLUGIN_DIR" ] && command -v git &>/dev/null; then
        if ! ping -w 3 'www.github.com' &>/dev/null; then
            echo "Error connecting to github servers. Skipping plugin init"
            return
        fi
        gh='https://github.com'
        for i in \
            "$gh/romkatv/zsh-defer" \
            "$gh/Aloxaf/fzf-tab" \
            "$gh/zdharma-continuum/fast-syntax-highlighting" \
            "$gh/zsh-users/zsh-autosuggestions"; do
            git clone "$i"
        done
        unset gh i
    fi
}

# plugin-install
