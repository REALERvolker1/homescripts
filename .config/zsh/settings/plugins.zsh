[[ $TERM == linux || $TTY == /dev/tty* || -n "${VLKPLUG_SKIP:-}" ]] && return

ZPLUGIN_DIR="$XDG_RUNTIME_DIR/zplugintest"
: "${ZPLUGIN_DIR:=${XDG_DATA_HOME:=$HOME/.local/share}/zsh-plugins}"
[[ ! -d $ZPLUGIN_DIR ]] && mkdir -p "$ZPLUGIN_DIR"

declare -a plugins=(
"url=https://github.com/zdharma-continuum/fast-syntax-highlighting
pluginfile=fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
\
"url=https://github.com/zsh-users/zsh-autosuggestions
pluginfile=zsh-autosuggestions/zsh-autosuggestions.zsh"
\
"url=https://github.com/Aloxaf/fzf-tab
pluginfile=fzf-tab/fzf-tab.zsh"
\
"url=undefined
pluginfile=/dev/null"
)

declare -i gitconnect_status=1
declare -a failplugs

# "${(@)plugins##*$'\n'pluginfile=}"
for i in "${(@)plugins}"; do
    plugin_file="${${i#*$'\n'pluginfile=}:=UNDEFINED}"
    [[ $plugin_file == '/'* ]] || plugin_file="$ZPLUGIN_DIR/$plugin_file"
    if [[ -f $plugin_file ]]; then
        zsh-defer . "$plugin_file"
    elif ((gitconnect_status == 2)); then
        failplugs+=("$plugin_file")
    else
        plugin_link="${${i#url=}%%$'\n'*}"
        if ((gitconnect_status == 3)); then
            if ! command -v git &>/dev/null; then
                echo "Error, missing critical dependency! (git)"
                return
            fi
        elif ((gitconnect_status == 1)); then
            echo "Checking connectivity to github..."
            if curl -sfL 'https://api.github.com' >/dev/null; then
                gitconnect_status=0
            else
                gitconnect_status=2
                echo "Could not connect to github!"
                failplugs+=("$plugin_file")
                continue
            fi
        fi
        git clone "$plugin_link" "${plugin_file%/*}"
        if [[ -f $plugin_file ]]; then
            zsh-defer . "$plugin_file"
        else
            failplugs+=("$plugin_file")
        fi
    fi
done

(($+failplugs)) && printf '⚠️ %s\n' "${(@)failplugs}"

unset plugins gitconnect_status failplugs plugin_file plugin_link i

__vlk_set_fast_theme() {
    if [[ "${FAST_THEME_NAME-}" != 'vlk-fsyh' ]]; then
        if typeset -f 'fast-theme' &>/dev/null && [ -f "$ZDOTDIR/settings/vlk-fsyh.ini" ]; then
            fast-theme "$ZDOTDIR/settings/vlk-fsyh.ini"
        fi
    fi
}
zsh-defer __vlk_set_fast_theme
