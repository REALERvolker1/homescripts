for i in "${__vlk_zsh_plugins[@]}"; do
    [[ "$i" != [a-zA-Z]*/[a-zA-Z]* ]] && {
        echo "Error, please input a valid github user/repo!"
        continue
    }
    file="$ZPLUGIN_DIR/${i#*/}/${i#*/}.plugin.zsh"
    [[ -f "$file" ]] && {
        zsh-defer . "$file"
        continue
    }

    command -v git &>/dev/null || {
        echo "Error, please install git!"
        continue
    }
    echo -en "Downloading \e[1m${i#*/}\e[0m..."
    git clone "https://github.com/${i}" "$ZPLUGIN_DIR/${i#*/}" &>/dev/null
    # autosuggestions just sources the file in the plugin
    if [[ "$i" == "zsh-users/zsh-autosuggestions" ]]; then
        command -p rm "$file"
        ln -sf "$ZPLUGIN_DIR/${i#*/}/${i#*/}.zsh" "$file"
    fi
    # overwrite loading text output
    if [ -f "$file" ]; then
        echo -e "\e[2K\r\e[1;92m[✅] ${i#*/}\e[0m"
        zsh-defer . "$file"
    else
        echo -e "\e[2K\r\e[1;91m[🟥] ${i#*/}\e[0m"
    fi
done

__vlk_set_fast_theme() {
    if [[ "${FAST_THEME_NAME:-}" != 'vlk-fsyh' ]]; then
        if typeset -f 'fast-theme' &>/dev/null && [ -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
}
zsh-defer __vlk_set_fast_theme
