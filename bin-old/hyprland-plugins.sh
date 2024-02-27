#!/usr/bin/bash
# script by vlk to install and/or update hyprland plugins
# Uses an A/B root system to make sure that everything is updated correctly
unsafe_mode() { set +euo pipefail; }
safe_mode() {
    set -euo pipefail
    IFS=$'\n\t'
}

safe_mode

if [[ ! -d "${HYPRLAND_PLUGIN_DIR:-}" ]]; then
    HYPRLAND_PLUGIN_DIR="${XDG_CACHE_HOME:=$HOME/.cache}/hyprplug"
fi

declare -A config=(
    [official_plugin]='https://github.com/hyprwm/hyprland-plugins'
    [builddir]="$HYPRLAND_PLUGIN_DIR/build"
    [rootfile]="$HYPRLAND_PLUGIN_DIR/current-root"
    [updatefile]="$HYPRLAND_PLUGIN_DIR/updatefile"
    [instfile]="$HYPRLAND_PLUGIN_DIR/instfile"
    [Aroot]="$HYPRLAND_PLUGIN_DIR/A.root"
    [Broot]="$HYPRLAND_PLUGIN_DIR/B.root"
    [current_root]=''
    [new_root]=''
)
config[official_plugin_builddir]="${config[builddir]}/official-plugins"

# might want to make a cool little effect with this plugin: https://github.com/micha4w/Hypr-DarkWindow
declare -a plugins=(
    'https://github.com/VortexCoyote/hyprfocus'
    # 'https://github.com/micha4w/Hypr-DarkWindow'
)

declare -a official_plugins=(
    "csgo-vulkan-fix"
    #"hyprtrails"
)

_panic() {
    printf '\e[1;31m%s\e[0m\n' "[${0##*/}] Panic!"
    _notify "$@"
    exit 1
}
_notify() {
    local header="${1:?Error, please insert a header!}"
    shift 1
    if [[ -t 1 ]]; then
        printf '%s\n' \
            "$(tput bold)$header$(tput sgr0)" \
            "$@"
    else
        notify-send "$header" "$(printf '%s\n' "$@")"
    fi
}

# dependency checking
declare -a faildeps=()
for i in git hyprctl jq notify-send bash cp; do
    command -v "$i" >/dev/null 2>&1 || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic 'Failed to find dependencies' "${faildeps[@]}"
unset faildeps

_install() {
    _notify "Installing plugins"
    mkdir -p "${config[new_root]}"
    for i in "${!official_plugins[@]}"; do
        official_plugins[i]="${config[official_plugin_builddir]}/${official_plugins[$i]}"
    done
    if [[ -d "${config[builddir]}" ]]; then
        rm -rf "${config[builddir]}"
    fi
    mkdir -p "${config[builddir]}"
    cd "${config[builddir]}"
    git clone "${config[official_plugin]}" "${config[official_plugin_builddir]}" &
    for i in "${plugins[@]}"; do
        git clone "$i" &
    done
    wait
    jobs
    for i in "${config[builddir]}"/* "${official_plugins[@]}"; do
        [[ -d "$i" && "$i" != "${config[official_plugin_builddir]}" ]] || continue
        cd "$i"
        echo "${i##*/} $(git rev-parse HEAD)" >"${config[instfile]}"
        _notify 'building plugin' "$i"
        make all || _panic "Failed to build plugin:" "$i"
        cp -rf ./*.so "${config[new_root]}"
    done
    echo "${config[new_root]}" >"${config[rootfile]}"
    config[current_root]="${config[new_root]}"
}

_load() {
    if ((UNSAFE)); then
        if [[ -t 0 && -t 1 ]]; then
            _notify "${0##*/}" "Currently in UNSAFE mode"
            read -r -p "Want to install plugins? [y/N] > " ans
            [[ "${ans:-n}" == y ]] || exit 1
            _install
        else
            _panic "Please run ${0##*/} in a terminal." "There were some issues loading plugins."
        fi
    fi
    ((${#HYPRLAND_INSTANCE_SIGNATURE})) || _panic 'Must be called from inside a hyprland session!'
    echo loading plugins
    unsafe_mode
    local i
    local -a errors=()
    local -a success=()
    for i in "${config[current_root]}"/*; do
        if [[ -f "$i" && "$i" == *.so ]]; then
            pluginmsg="(${i##*/}) $(hyprctl plugin load "$i")"
            if [[ "$pluginmsg" != *') error'* ]]; then
                success+=("$pluginmsg")
            else
                errors+=("$pluginmsg")
            fi
        fi
    done
    safe_mode
    ((${#errors[@]})) && _panic "Error loading plugins" "${errors[@]}"
    ((${#success[@]})) || _panic "Error loading plugins" "No plugins could be loaded!"
    [[ -e "${config[updatefile]}" ]] && rm "${config[updatefile]}"
}

_checkupdate() {
    if [[ ! -f "${config[updatefile]}" ]]; then
        local i
        for i in "${config[builddir]}"/*; do
            (
                cd "$i"
                git pull
                details="${i##*/} $(git rev-parse HEAD)"
                if ! grep -q "^${details}\$" "${config[instfile]}"; then
                    echo "$details" >"${config[updatefile]}"
                fi
            ) &
        done
    fi

    if [[ -f "${config[updatefile]}" ]]; then
        _notify "Outdated plugins" "$(cat "${config[updatefile]}")"
        return 1
    else
        return 0
    fi
}

declare -i UNSAFE=0
if [[ ! -d "$HYPRLAND_PLUGIN_DIR" ]]; then
    UNSAFE=1
    mkdir -p "$HYPRLAND_PLUGIN_DIR"
fi

if [[ -f "${config[rootfile]}" ]]; then
    config[current_root]="$(<"${config[rootfile]}")"
    [[ -d "${config[current_root]}" ]] || config[current_root]=''
fi

case "${config[current_root]}" in
"${config[Aroot]}")
    config[new_root]="${config[Broot]}"
    ;;
"${config[Broot]}")
    config[new_root]="${config[Aroot]}"
    ;;
*)
    UNSAFE=1
    config[new_root]="${config[Aroot]}"
    ;;
esac

case "${1:-null}" in
--load | -l)
    _load
    ;;
--install | -i)
    _install
    ;;
--update | -u)
    _checkupdate || _install
    ;;
--check | -c)
    _checkupdate
    ;;
# --update (-u)     update plugins
--clean | -r)
    rm -rf "$HYPRLAND_PLUGIN_DIR"
    ;;
*)
    cat <<BRUH
Error, invalid argument: \`${i:-}\`
Supported args:

--load (-l)       load plugins in current hyprland session
--install (-i)    (re)install plugins
--update (-u)     Update plugins
--check (-c)      Check for updates, but don't download
--clean (-r)      completely remove plugin cache and installed plugins
BRUH
    ;;
esac

wait
