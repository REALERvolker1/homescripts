# shellcheck shell=bash disable=2155,2153,1090,1091,2206,2296,2298,2190
# vim:foldmethod=marker:ft=sh
# a script by vlk to load environment variables for bash and zsh shells.
# Intended to be resilient even if the shell is launched with `env -i`

# unset any safe mode, it is not intended for interactive shells
set +euo pipefail
# printenv >~/vlkenvcache
# add /bin to path just in case
PATH="${PATH:+$PATH:}/usr/bin"

unset MAILCHECK
[[ ${LANG:-C} == C ]] && export LANG='en_US.UTF-8'
echo -n '[0m'
export TTY="${TTY:-$(tty)}"

# set the terminal TERM variable to fix shell behavior
if [[ -z ${TERM-} ]]; then
    if ! tput &>/dev/null; then
        case "${TTY:=$(tty)}" in
        /dev/pts*) export TERM='xterm-256color' ;;
        *) export TERM=linux ;;
        esac
        echo "TERM not set! Falling back to $TERM"
    fi
fi

# deactivate virtual environments
if [[ -n ${CONDA_PREFIX-} ]]; then
    echo "Deactivating CONDA_PREFIX '$CONDA_PREFIX'"
    conda deactivate
fi
if [[ -n ${VIRTUAL_ENV-} ]]; then
    echo "Deactivating VIRTUAL_ENV '$VIRTUAL_ENV'"
    deactivate
fi

# set paramters that are important for my shell setup
export CURRENT_DISTRO="${CURRENT_DISTRO:-$(grep -oP '^NAME="\K[^ ]*' /etc/os-release)}"
export CURRENT_HOSTNAME='undefined'
# export CURRENT_DISTRO CURRENT_HOSTNAME

if [[ -z ${HOST-} ]]; then
    if [[ -n ${HOSTNAME-} ]]; then
        export HOST="$HOSTNAME"
    elif command -v hostnamectl >/dev/null 2>&1; then
        export HOST="$(hostnamectl hostname)"
    elif [[ -f /etc/hostname ]]; then
        export HOST="$(cat /etc/hostname)"
    fi
fi
export HOSTNAME="${HOSTNAME:-$HOST}"
export USER="${USER:-$(whoami || true)}"
export HOME="${HOME:-/home/$USER}"
export UID="${UID:-$(id -u "$USER" || true)}"

# xdg dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# make them if they don't exist
if [[ -d $XDG_CONFIG_HOME && -d $XDG_DATA_HOME && -d $XDG_CACHE_HOME && -d $XDG_STATE_HOME ]]; then
    true
else
    while read -r line; do
        xdg_varname="${line%%=*}"
        xdg_dirname="${line#*=}"
        if [[ -d ${xdg_varname-} ]]; then
            continue
        elif mkdir -p "$xdg_dirname"; then
            echo "Created \$$xdg_varname: '$xdg_dirname'"
        else
            echo "[1mError, failed to create \$$xdg_varname '$xdg_dirname'[0m"
            unset "$xdg_varname"
        fi
    done <<<"XDG_CONFIG_HOME=$XDG_CONFIG_HOME
XDG_DATA_HOME=$XDG_DATA_HOME
XDG_CACHE_HOME=$XDG_CACHE_HOME
XDG_STATE_HOME=$XDG_STATE_HOME"

    unset line xdg_dirname xdg_varname
fi

# set important XDG variables
if [[ -d ${XDG_RUNTIME_DIR-} && -w ${XDG_RUNTIME_DIR-} && -r ${XDG_RUNTIME_DIR-} ]]; then
    export XDG_RUNTIME_DIR
else
    __old_runtime_dir="${XDG_RUNTIME_DIR-}"
    if [[ -d "/run/user/$UID" && -w "/run/user/$UID" && -r "/run/user/$UID" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$UID"
    elif [[ -d /tmp && -w /tmp && -r /tmp ]]; then
        mkdir "/tmp/fallback_runtime_dir_${USER-}"
        export XDG_RUNTIME_DIR="/tmp/fallback_runtime_dir_${USER-}"
    else
        mkdir "$HOME/.run"
        export XDG_RUNTIME_DIR="$HOME/.run"
    fi
    echo "Error, invalid XDG_RUNTIME_DIR '${__old_runtime_dir}'! Resetting to '$XDG_RUNTIME_DIR'"
    unset __old_runtime_dir
fi
if [[ -z ${XDG_VTNR-} ]]; then
    XDG_VTNR="$(w -hu | grep -m 1 -oP "^[^\s]*\s*tty\K[0-9]+" || true)"
    if [[ -n ${XDG_VTNR-} ]]; then
        export XDG_VTNR
        echo "Setting XDG_VTNR to $XDG_VTNR"
    else
        unset XDG_VTNR
    fi
fi
if [[ -z ${XDG_SESSION_ID-} ]]; then
    if command -v loginctl &>/dev/null; then
        XDG_SESSION_ID="$(loginctl list-sessions --no-pager --no-legend | cut -d ' ' -f 1 | xargs loginctl show-session -p Id -p Active | tr '\n' ' ' | grep -oP 'Id=\K[0-9]+(?= Active=yes)' | head -n 1 || true)"
        # XDG_SESSION_ID="$(loginctl --output=json | jq -r '.[] | select(.state == "active").session' | head -n 1 || true)"
        if [[ -n ${XDG_SESSION_ID-} ]]; then
            export XDG_SESSION_ID
            echo "Setting XDG_SESSION_ID to $XDG_SESSION_ID"
        else
            unset XDG_SESSION_ID
        fi
    else
        unset XDG_SESSION_ID
    fi
fi

# set LS_COLORS
__dircolor_cache="$XDG_RUNTIME_DIR/dircolors.cache"
#if [[ -f "$__dircolor_cache" && -n ${EXPORTED_LS_COLORS-} && -n ${LS_COLORS-} ]]; then
    #export LS_COLORS
#else
    if [[ ! -f "$__dircolor_cache" ]]; then
        for i in {"${XDG_CONFIG_HOME:=$HOME/.config}",$HOME}/{,.}dir_colors; do
            if [[ -r $i ]]; then
                dircolors --sh "$i" | sed 's/^ex.*$// ; s/^LS/export LS/' >"$__dircolor_cache" && break
                [[ -n ${ZSH_VERSION-} ]] && zcompile "$i"
                break
            fi
        done
    fi
    if . "$__dircolor_cache"; then
        # [[ -n ${ZSH_VERSION-} ]] && type zcompile &>/dev/null && zcompile "$__dircolor_cache"
        export LS_COLORS
        [[ -e /etc/profile.d/colorls.sh ]] && export USER_LS_COLORS=true
        export EXPORTED_LS_COLORS=true
    else
        echo "Error loading dircolors cache!"
    fi
#fi
unset __dircolor_cache

if [[ ${EDITOR-} != nvim ]]; then
    # unset EDITOR
    if command -v nvim &>/dev/null; then
        export EDITOR="nvim"
        export MANPAGER='nvim +Man\!'
    else
        for i in vim hx micro vi nano; do
            if command -v "$i" &>/dev/null; then
                export EDITOR="$i"
                break
            fi
        done
    fi
fi
[[ -n ${EDITOR-} ]] && export VISUAL="$EDITOR"
export PAGER='less'

if command -v batpipe >/dev/null 2>&1; then
    export LESSOPEN="|/usr/bin/batpipe %s"
    unset LESSCLOSE
    export LESS="${LESS-} -R"
    export BATPIPE=color
fi

# export VLK_VSC='/usr/bin/code'
export TERMINAL='vlk-sensible-terminal 1'
export BROWSER='vlk-sensible-browser 1'
export HOMESCRIPTS="$HOME/random/homescripts"

# shell rcfiles
export ENV="$XDG_CONFIG_HOME/dashrc"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export BDOTDIR="$XDG_CONFIG_HOME/bash"

# export LESSOPEN="||/usr/bin/lesspipe.sh %s"

export GREP_COLORS="mt=01;91:fn=03;32:ln=33:bn=36:se=35"
export JQ_COLORS="0;31:0;36:1;36:0;33:1;32:0;37:1;37"
# VLK_COLOR_REFERENCE="accent=#7a5dfc:accent_l=#af99ff:err=#FF5050:bg=#272B33:"
export SUDO_PROMPT="[0;1m[[31mSUDO[0;1m][0m "
export FZF_DEFAULT_OPTS="--prompt=' ' --pointer=' ' --marker=' ' --tabstop=4 --no-mouse --ansi \
--color=fg:#ccccdc,hl:#df6b75,fg+:#fcfcff,bg+:#2c323d,hl+:#d682f0,info:#f2ce97,prompt:#d7005f,pointer:#65b6f8,marker:#56b5c2,spinner:#d682f0,header:#e6e6e6 "

# rofi
export ROFI_ICON_NORMAL='#e2e4e9'
export ROFI_ICON_URGENT='#16181d'
export ROFI_ICON_ACTIVE='#16181d'

# x11
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
export XRESOURCES="$XDG_CONFIG_HOME/X11/Xresources"

# hists
export HISTFILE="$XDG_RUNTIME_DIR/shellhist"
export LESSHISTFILE='/dev/null'
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"

# qt customzation
export QT_QPA_PLATFORMTHEME='qt5ct'
export QT_QPA_PLATFORM_PLUGIN_PATH="$XDG_CONFIG_HOME" #QT_STYLE_OVERRIDE='kvantum'

# wayland
export MOZ_ENABLE_WAYLAND=1
export GTK_USE_PORTAL=1

# random xdg shit
export WINEPREFIX="$XDG_DATA_HOME/wine"
export DVDCSS_CACHE="$XDG_DATA_HOME/dvdcss"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export RXVT_SOCKET="$XDG_RUNTIME_DIR/urxvtd"
export W3M_DIR="$XDG_STATE_HOME/w3m"
export MACHINE_STORAGE_PATH="$XDG_DATA_HOME/docker-machine"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export OLLAMA_HOME="$XDG_DATA_HOME/ollama"
export FCEUX_HOME="$XDG_CONFIG_HOME/fceux"

# nix
export VLK_NIX_HOME="$XDG_STATE_HOME/nix/profile"
# fix nix XDG being trash
#if [[ ${NIX_PATH-} != *"$XDG_STATE_HOME/nix/channels"* ]]; then
#    NIX_PATH="${NIX_PATH:+$NIX_PATH:}$XDG_STATE_HOME/nix/channels"
#fi
if [[ ":${NIX_PATH-}:" != *":$XDG_STATE_HOME/nix/defexpr/channels:"* ]]; then
    export NIX_PATH="${NIX_PATH:+$NIX_PATH:}$XDG_STATE_HOME/nix/defexpr/channels"
fi
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

# old GTK versions
export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# java
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_CONFIG_HOME/java\""
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export JAVA_HOME='/usr/lib/jvm/java-17-openjdk-17.0.8.0.7-1.fc38.x86_64'
export INSTALL4J_JAVA_HOME="${JAVA_HOME:-}"

# perl
export PERL_CPANM_HOME="$XDG_CACHE_HOME/cpanm"

# rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"

# golang
export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOMODCACHE="${GOPATH:=$XDG_DATA_HOME/go}/pkg/mod"

# python
export PYTHONUSERBASE="$XDG_DATA_HOME/python"
#export PYTHONUSERBASE="$XDG_DATA_HOME/pythonuserbase"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/pythonrc"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export PYTHON_EGG_CACHE="$XDG_CACHE_HOME/python-eggs"
export WORKON_HOME="$XDG_DATA_HOME/virtualenvs"

# nodejs
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NODENV_ROOT="$XDG_DATA_HOME/nodenv"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export YARN_ENABLE_TELEMETRY=0
export NVM_DIR="$XDG_DATA_HOME/nvm"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export DENO_INSTALL="$XDG_DATA_HOME/deno"

# keyring
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GPG_TTY="$TTY"
export GNOME_KEYRING_CONTROL="${GNOME_KEYRING_CONTROL:-$XDG_RUNTIME_DIR/keyring}"
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/keyring/ssh}"

if [[ -S "$XDG_RUNTIME_DIR/.ydotool_socket" ]]; then
    export YDOTOOL_SOCKET="$XDG_RUNTIME_DIR/.ydotool_socket"
elif [[ -S /tmp/.ydotool_socket ]]; then
    export YDOTOOL_SOCKET='/tmp/.ydotool_socket'
fi

if [[ -n ${BASH_VERSION-} ]]; then
    __pathmunge() {
        local -A __path
        local hpath
        local -i idx=0
        for i in "${dir_pref_before[@]}"; do
            i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
            __path[$i]="$idx:$i"
            idx+=1
        done
        while read -r -d ':' i; do
            i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
            if [[ -z ${__path[$i]-} ]]; then
                __path[$i]="$idx:$i"
                idx+=1
            fi
        done <<<"$INIT_PATH"
        for i in "${dir_pref_after[@]}"; do
            i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
            __path[$i]="$idx:$i"
            idx+=1
        done
        hpath="$(printf '%s\n' "${__path[@]}" | sort -n | cut -d : -f 2 | tr -s '\n' :)"
        [[ -z ${essentials-} || ":${hpath-}:" == *":$essentials:"* ]] || hpath="${hpath}:${essentials}"
        echo "$hpath"
    }
elif [[ -n ${ZSH_VERSION-} ]]; then
    __pathmunge() {
        local -aU __path=(${dir_pref_before:A} ${${(s.:.)INIT_PATH}:A})
        local -aU __zshpath
        local hpath
        for i in ${__path:|dir_pref_after} ${dir_pref_after:A}; do
            [[ -d $i ]] && __zshpath+=($i)
        done
        hpath="${(j.:.)__zshpath}"
        [[ -z ${essentials-} || ":${hpath-}:" == *":$essentials:"* ]] || hpath="${hpath}:${essentials}" #"
        print "$hpath"
    }
fi

typeset -a dir_pref_{before,after}

dir_pref_before=(
    "$HOME/"{,.local}/bin
    {"$VLK_NIX_HOME","$CARGO_HOME","$GOPATH","$BUN_INSTALL","$PYTHONUSERBASE"}/bin
    "$PNPM_HOME"
    {"$XDG_DATA_HOME",/var/lib}/flatpak/exports/bin
)
dir_pref_after=(
    /usr{/local,}/bin
)
essentials='/usr/bin'
INIT_PATH="${PATH-}"
PATH="$(__pathmunge)"
export PATH

dir_pref_before=(
    "$XDG_DATA_HOME"
    "$VLK_NIX_HOME/share"
    {"$XDG_DATA_HOME",/var/lib}/flatpak/exports/share
)
dir_pref_after=(
    /usr{/local,}/share
)
# I have zero trust when it comes to this shit
#essentials='/var/lib/flatpak/exports/share:/usr/local/share:/usr/share'
essentials=/usr/share
INIT_PATH="${XDG_DATA_DIRS-}"
XDG_DATA_DIRS="$(__pathmunge)"
export XDG_DATA_DIRS

unset i ICON_TYPE dir_pref_{before,after} essentials INIT_PATH
unset -f __pathmunge

if [[ -n ${VTE_VERSION-} ]]; then
    export ICON_TYPE='dashline'
else
    case "$TERM" in
    *kitty* | *alacritty* | *foot*) export ICON_TYPE='dashline' ;;
    *) export ICON_TYPE='fallback' ;;
    esac
fi
