# shellcheck shell=bash
# shellcheck disable=2155,2153
# vim:foldmethod=marker:ft=sh

unset MAILCHECK
[[ "${LANG:-C}" == 'C' ]] && export LANG="en_US.UTF-8"

if [[ -n "${CONDA_PREFIX:-}" ]]; then
    conda deactivate
    echo "\$CONDA_PREFIX '$CONDA_PREFIX' deactivated"
fi
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    deactivate
    echo "\$VIRTUAL_ENV '$VIRTUAL_ENV' deactivated"
fi

export CURRENT_DISTRO="${CURRENT_DISTRO:-$(grep -oP '^NAME="\K[^ ]*' /etc/os-release)}"
export CURRENT_HOSTNAME='iphone'
: "${HOST:=$(cat /etc/hostname)}"
export HOME="${HOME:-/home/$(whoami)}" HOSTNAME="${HOSTNAME:-$HOST}"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share" XDG_CACHE_HOME="$HOME/.cache" XDG_STATE_HOME="$HOME/.local/state"

if [[ "${EDITOR:-}" != 'nvim' ]]; then
    # unset EDITOR
    if command -v nvim &>/dev/null; then
        export EDITOR="nvim"
        export MANPAGER='nvim +Man\!'
    else
        for i in vim hx micro vi nano; do
            command -v "$i" &>/dev/null && export EDITOR="$i" && break
        done
    fi
fi

[[ -n "${EDITOR:-}" ]] && export VISUAL="$EDITOR"
export TERMINAL='vlk-sensible-terminal 1' BROWSER='vlk-sensible-browser 1'
# export PAGER='less'
export HOMESCRIPTS="$HOME/random/homescripts"

# shell rcfiles
export ENV="$XDG_CONFIG_HOME/dashrc" ZDOTDIR="$XDG_CONFIG_HOME/zsh" BDOTDIR="$XDG_CONFIG_HOME/bash"

# LS customization
export LS_PATH="${LS_PATH:-/usr/bin/ls}" WHICH_PATH="${WHICH_PATH:-/usr/bin/which}" RM_PATH="${RM_PATH:=/usr/bin/rm}" VIM_PATH="${VIM_PATH:=/usr/bin/vim}"
export LA_COMMAND="$LS_PATH --color=auto --group-directories-first -A"
if command -v lsd &>/dev/null; then
    export LS_COMMAND='lsd' LL_COMMAND='lsd -l'
else
    export LS_COMMAND="$LA_COMMAND" LL_COMMAND="$LA_COMMAND -l"
fi
case "${LS_COLORS:-}" in
*':*rc='*) : ;;
*)
    . <(dircolors --sh "$XDG_CONFIG_HOME/dir_colors" || dircolors --sh || echo 'echo error loading dircolors')
    ;;
esac
export LESSOPEN="||/usr/bin/lesspipe.sh %s"
[ -z "${USER_LS_COLORS:-}" ] && export USER_LS_COLORS="$LS_COLORS"
DIRECTORY_COLOR="${LS_COLORS##*:di=}"
export DIRECTORY_COLOR="${DIRECTORY_COLOR%%:*}" GREP_COLORS="mt=01;91:fn=03;32:ln=33:bn=36:se=35" JQ_COLORS="0;31:0;36:1;36:0;33:1;32:0;37:1;37"
export VLK_COLOR_REFERENCE="accent=#7a5dfc:accent_l=#af99ff:err=#FF5050:bg=#272B33:"
export SUDO_PROMPT="[0;1m[[31mSUDO[0;1m][0m "
export FZF_DEFAULT_OPTS="--prompt=' ' --pointer=' ' --marker=' ' --tabstop=4 --no-mouse --ansi \
--color=fg:#ccccdc,hl:#df6b75,fg+:#fcfcff,bg+:#2c323d,hl+:#d682f0,info:#f2ce97,prompt:#d7005f,pointer:#65b6f8,marker:#56b5c2,spinner:#d682f0,header:#e6e6e6 "
# rofi
export ROFI_ICON_NORMAL='#e2e4e9' ROFI_ICON_URGENT='#16181d' ROFI_ICON_ACTIVE='#16181d'
# x11
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc" XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc" XRESOURCES="$XDG_CONFIG_HOME/X11/Xresources"
# hists
export HISTFILE="$XDG_RUNTIME_DIR/shellhist" LESSHISTFILE='/dev/null'
# qt customzation
export QT_QPA_PLATFORMTHEME='qt5ct' QT_QPA_PLATFORM_PLUGIN_PATH="$XDG_CONFIG_HOME" #QT_STYLE_OVERRIDE='kvantum'
# wayland
export MOZ_ENABLE_WAYLAND=1 GTK_USE_PORTAL=1
# random xdg shit
export WINEPREFIX="$XDG_DATA_HOME/wine" DVDCSS_CACHE="$XDG_DATA_HOME/dvdcss" CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv" RXVT_SOCKET="$XDG_RUNTIME_DIR/urxvtd" W3M_DIR="$XDG_STATE_HOME/w3m" MACHINE_STORAGE_PATH="$XDG_DATA_HOME/docker-machine" MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history" INPUTRC="$XDG_CONFIG_HOME/readline/inputrc" GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc" GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
# java
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\"" GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export JAVA_HOME='/usr/lib/jvm/java-17-openjdk-17.0.8.0.7-1.fc38.x86_64'
export INSTALL4J_JAVA_HOME="${JAVA_HOME:-}"
# perl
export PERL_CPANM_HOME="$XDG_CACHE_HOME/cpanm"
# rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup" CARGO_HOME="$XDG_DATA_HOME/cargo"
# golang
export GOPATH="$XDG_DATA_HOME/go" GOCACHE="$XDG_CACHE_HOME/go-build" GOMODCACHE="${GOPATH:-$XDG_DATA_HOME/go}/pkg/mod"
# python
# PYTHONUSERBASE="$XDG_DATA_HOME/python"
export PYTHONUSERBASE="$XDG_DATA_HOME/pythonuserbase"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc" PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python" PYENV_ROOT="$XDG_DATA_HOME/pyenv" PYTHON_EGG_CACHE="$XDG_CACHE_HOME/python-eggs" WORKON_HOME="$XDG_DATA_HOME/virtualenvs"
# nodejs
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc" NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm" NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history" NODENV_ROOT="$XDG_DATA_HOME/nodenv" PNPM_HOME="$XDG_DATA_HOME/pnpm" YARN_ENABLE_TELEMETRY=0 NVM_DIR="$XDG_DATA_HOME/nvm" BUN_INSTALL="$XDG_DATA_HOME/bun" DENO_INSTALL="$XDG_DATA_HOME/deno"
# keyring
export GNUPGHOME="$XDG_DATA_HOME/gnupg" GPG_TTY="${TTY:=$(tty)}"
export GNOME_KEYRING_CONTROL="${GNOME_KEYRING_CONTROL:-$XDG_RUNTIME_DIR/keyring}" SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/keyring/ssh}"

# export OLLAMA_HOME="$XDG_DATA_HOME/ollama"

if [[ -S "$XDG_RUNTIME_DIR/.ydotool_socket" ]]; then
    export YDOTOOL_SOCKET="$XDG_RUNTIME_DIR/.ydotool_socket"
elif [[ -S /tmp/.ydotool_socket ]]; then
    export YDOTOOL_SOCKET='/tmp/.ydotool_socket'
fi

# __vlkenv_pathmunge_bin="$XDG_CONFIG_HOME/shell/rustcfg/pathmunge/target/release/pathmunge"
__vlkenv_pathmunge_bin="$XDG_CONFIG_HOME/rustcfg/pathmunge/target/release/pathmunge"
if [[ ! -x "$__vlkenv_pathmunge_bin" ]]; then
    if command -v cargo &>/dev/null; then
        if [[ "$-" == *i* ]]; then
            tgtdir="${__vlkenv_pathmunge_bin%/target*}"
            lastpath="${PWD:-$(pwd)}"
            if [ -d "$tgtdir" ]; then
                builtin cd "$tgtdir" || :
                cargo build --release
                builtin cd "$lastpath" || :
            else
                echo "vlkenv pathmunge not found. falling back to default."
            fi
            unset tgtdir lastpath
        else
            echo "Not in interactive mode: Skipping building pathmunge"
        fi
    else
        echo "Cargo not found. Skipping building pathmunge"
    fi
    __pathmunge_helper_function() {
        case ":${pathlike}:" in
        *":${1}:"*) true ;;
        *) [ -d "$1" ] && tmppth="$1${tmppth:+:$tmppth}" ;;
        esac
    }
    __pathmunge() {
        pathlike=''
        tmppth=''
        for i in "$@"; do
            case "${i:-}" in
            '--pathlike='*)
                for j in $(echo "${i#*=}" | sed 's/:/ /g'); do
                    __pathmunge_helper_function "$j"
                done
                ;;
            *)
                __pathmunge_helper_function "$i"
                ;;
            esac
        done
        echo "$tmppth"
    }
    __vlkenv_pathmunge_bin='__pathmunge'
fi

export XDG_DATA_DIRS="$(
    $__vlkenv_pathmunge_bin \
        "$XDG_DATA_HOME" \
        "$XDG_DATA_HOME/flatpak/exports/share" \
        '/var/lib/flatpak/exports/share' \
        '/usr/local/share' \
        '/usr/share' \
        --pathlike="$XDG_DATA_DIRS"
)" PATH="$(
    $__vlkenv_pathmunge_bin \
        "$HOME/bin" \
        "$HOME/.local/bin" \
        "${CARGO_HOME:-ch}/bin" \
        "${GOPATH:-gp}/bin" \
        "${BUN_INSTALL:-bi}/bin" \
        "${PNPM_HOME:-ph}" \
        "${PYTHONUSERBASE:-pu}/bin" \
        "$XDG_DATA_HOME/flatpak/exports/bin" \
        '/var/lib/flatpak/exports/bin' \
        '/usr/local/bin' \
        --pathlike="$PATH"
)"
if [ "${__vlkenv_pathmunge_bin:-}" = '__pathmunge' ]; then
    unset -f __pathmunge
    unset -f __pathmunge_helper_function
fi
unset oldifs pathlike tmppth i j ICON_TYPE __vlkenv_pathmunge_bin

if [ -n "${VTE_VERSION:-}" ]; then
    export ICON_TYPE='dashline'
else
    case "$TERM" in
    *kitty* | *alacritty* | *foot*) export ICON_TYPE='dashline' ;;
    *) export ICON_TYPE='fallback' ;;
    esac
fi