# a script by vlk to load environment variables for zsh

# use zsh emulation, don't do any weirdness with arrays and whatnot
emulate -LR zsh

# add /bin to path just in case
PATH="${PATH:+$PATH:}/usr/bin"

unset MAILCHECK
[[ ${LANG:-C} == C ]] && export LANG='en_US.UTF-8'
echo -n '[0m'

if [[ $IFS != $' \t\n\C-@' ]] {
    echo 'Resetting non-default IFS'
    IFS=$' \t\n\C-@'
}

i=${TTY:-$(tty)}
# we are in an interactive session
if [[ -o i && -t 0 && -t 1 && -t 2 && -e $i ]] {
    export TTY=$i
    (($+TERM)) || export TERM=${$([[ $TTY =~ pts ]] && print xterm-256color):-linux}
}

# deactivate virtual environments
if ((${+CONDA_PREFIX})) {
    print "Deactivating CONDA_PREFIX '$CONDA_PREFIX'"
    conda deactivate
}
if ((${+VIRTUAL_ENV})) {
    print "Deactivating VIRTUAL_ENV '$VIRTUAL_ENV'"
    deactivate
}

# set paramters that are important for my shell setup
# export CURRENT_DISTRO="${CURRENT_DISTRO:-$(grep -oP '^NAME="\K[^ ]*' /etc/os-release)}"
CURRENT_HOSTNAME='undefined'
# export CURRENT_DISTRO CURRENT_HOSTNAME

: ${HOSTNAME::=${HOST:=${HOSTNAME:=$(
    if [[ -f /etc/hostname ]] {
        </etc/hostname
    } elif ((${+commands[hostname]})) {
        =hostname
    } elif ((${+commands[hostnamectl]})) {
        =hostnamectl hostname
    }
)}}}

export HOST{,NAME}

[[ -n ${USER:=$(=whoami)} ]] && export USER
[[ -d ${HOME:=~} ]] && export HOME
[[ -n ${UID:=$(=id -u $USER)} ]] && export UID

for i j in \
    XDG_CONFIG_HOME ${XDG_CONFIG_HOME:-$HOME/.config} \
    XDG_DATA_HOME ${XDG_DATA_HOME:-$HOME/.local/share} \
    XDG_CACHE_HOME ${XDG_CACHE_HOME:-$HOME/.cache} \
    XDG_STATE_HOME ${XDG_STATE_HOME:-$HOME/.local/state}
    [[ -d $j ]] && export $i=$j

# runtimedirstat=$(=stat --format='%a' $XDG_RUNTIME_DIR)
# if ((${runtimedirstat:=0} != 700)) {
#     =chmod 700 $XDG_RUNTIME_DIR || print -l \
#         "Error, \$XDG_RUNTIME_DIR has invalid permissions! ($runtimedirstat)" \
#         "https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html"
# }
if [[ -d ${XDG_RUNTIME_DIR-} ]] {
    export XDG_RUNTIME_DIR
    export GNOME_KEYRING_CONTROL="${GNOME_KEYRING_CONTROL:-$XDG_RUNTIME_DIR/keyring}"
    export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/keyring/ssh}"

    __dircolor_cache="$XDG_RUNTIME_DIR/dircolors.cache"
} else {
    __dircolor_cache=/dev/null
}


__dircolors_default="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:\
or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:\
*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:\
*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:\
*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:\
*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:\
*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:\
*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:\
*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:\
*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:\
*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:\
*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:\
*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:\
*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:\
*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:\
*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:"
[[ -w ${__dircolor_cache:h} && ! -f $__dircolor_cache ]] &&
    echo 'Making dircolor cache!' &&
    COLORTERM=truecolor =dircolors --sh "$XDG_CONFIG_HOME/dir_colors" >"$__dircolor_cache" &&
        zcompile "$__dircolor_cache"

[[ -r "$__dircolor_cache" ]] &&
    . "$__dircolor_cache" &&
        [[ -e /etc/profile.d/colorls.sh ]] &&
            export USER_LS_COLORS=true
# I don't want to eval Fedora's entire colorls script with tons of grep and whatnot, no thank you!

export LS_COLORS="${LS_COLORS:-$__dircolors_default}"

unset __dircolor_cache

if [[ ${EDITOR-} != nvim ]] {
    # unset EDITOR
    if ((${+commands[nvim]})) {
        export EDITOR=nvim
        export MANPAGER='nvim +Man\!'
    } else {
        for EDITOR in vim hx micro vi nano ''
            ((${+commands[$EDITOR]})) && break
        ((${#EDITOR})) || unset EDITOR
    }
}
((${+EDITOR})) && export VISUAL="$EDITOR"
export PAGER=less

if ((${+commands[batpipe]})) {
    export LESSOPEN="|${commands[batpipe]} %s"
    unset LESSCLOSE
    export LESS="${LESS-} -R"
    export BATPIPE=color
} elif ((${+commands[lesspipe.sh]})) {
    export LESSOPEN="|${commands[lesspipe.sh]} %s"
}

export TERMINAL='vlk-sensible-terminal 1'
export BROWSER='vlk-sensible-browser --choose'
export HOMESCRIPTS="$HOME/random/homescripts"

# shell rcfiles
export ENV="$XDG_CONFIG_HOME/dashrc"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZPLUGIN_DIR="$XDG_DATA_HOME/zsh-plugins"
export BDOTDIR="$XDG_CONFIG_HOME/bash"

export GREP_COLORS="mt=01;91:fn=03;32:ln=33:bn=36:se=35"
export JQ_COLORS="0;31:0;36:1;36:0;33:1;32:0;37:1;37"
# VLK_COLOR_REFERENCE="accent=#7a5dfc:accent_l=#af99ff:err=#FF5050:bg=#272B33:"
export SUDO_PROMPT="[0;1m[[31mSUDO[0;1m][0m "
export FZF_DEFAULT_OPTS="--prompt=' ' --pointer=' ' --marker=' ' --tabstop=4 --no-mouse --ansi \
--color=fg:#ccccdc,hl:#df6b75,fg+:#fcfcff,bg+:#2c323d,hl+:#d682f0,info:#f2ce97,prompt:#d7005f,pointer:#65b6f8,marker:#56b5c2,spinner:#d682f0,header:#e6e6e6 "

# rofi
# export ROFI_ICON_NORMAL='#e2e4e9'
# export ROFI_ICON_URGENT='#16181d'
# export ROFI_ICON_ACTIVE='#16181d'

# x11
i=$XDG_CONFIG_HOME/X11
export XINITRC="$i/xinitrc"
export XSERVERRC="$i/xserverrc"
export XRESOURCES="$i/Xresources"

# hists
export HISTFILE="$XDG_CACHE_HOME/shellhist"
export LESSHISTFILE=/dev/null
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"

# qt customzation
export QT_QPA_PLATFORMTHEME='qt5ct'
export QT_QPA_PLATFORM_PLUGIN_PATH="$XDG_CONFIG_HOME"
# export QT_STYLE_OVERRIDE='kvantum'

# wayland
export MOZ_ENABLE_WAYLAND=1
export GTK_USE_PORTAL=1

# random xdg shit
export WINEPREFIX="$XDG_DATA_HOME/wine"
export DVDCSS_CACHE="$XDG_CACHE_HOME/dvdcss"
export CUDA_CACHE_PATH="$XDG_CACHE_HOME/nv"
export RXVT_SOCKET="${XDG_RUNTIME_DIR:-$XDG_CACHE_HOME}/urxvtd"
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
[[ ":${NIX_PATH-}:" != *":$XDG_STATE_HOME/nix/defexpr/channels:"* ]] &&
    export NIX_PATH="${NIX_PATH:+$NIX_PATH:}$XDG_STATE_HOME/nix/defexpr/channels"

export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

# old GTK versions
# export GTK_RC_FILES="$XDG_CONFIG_HOME/gtk-1.0/gtkrc"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# java
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=\"$XDG_STATE_HOME/java\"" # doesn't do jack shit
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
# export JAVA_HOME=/usr/lib/jvm/default
# [[ -n ${JAVA_HOME-} ]] && export INSTALL4J_JAVA_HOME=${JAVA_HOME-}

# perl
export PERL_CPANM_HOME="$XDG_DATA_HOME/cpanm"

# rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"

# golang
export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export GOMODCACHE="$GOPATH/pkg/mod"

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
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export NODENV_ROOT="$XDG_DATA_HOME/nodenv"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export YARN_ENABLE_TELEMETRY=0
export NVM_DIR="$XDG_DATA_HOME/nvm"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export DENO_INSTALL="$XDG_DATA_HOME/deno"

# keyring
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GPG_TTY="$TTY"

if [[ -S "$XDG_RUNTIME_DIR/.ydotool_socket" ]]; then
    export YDOTOOL_SOCKET="$XDG_RUNTIME_DIR/.ydotool_socket"
elif [[ -S /tmp/.ydotool_socket ]]; then
    export YDOTOOL_SOCKET='/tmp/.ydotool_socket'
fi

__pathmunge() {
    local -aU __path=(${dir_pref_before:A} ${${(s.:.)INIT_PATH}:A})
    local -aU __zshpath
    local hpath
    for i in ${__path:|dir_pref_after} ${dir_pref_after:A}
        [[ -d $i ]] && __zshpath+=($i)
    hpath="${(j.:.)__zshpath}"
    [[ -z ${essentials-} || ":${hpath-}:" == *":$essentials:"* ]] || hpath="${hpath}:${essentials}"
    print "$hpath"
}

export PATH="$(
    dir_pref_before=(
        {$HOME/{,.local},$VLK_NIX_HOME,$CARGO_HOME,$GOPATH,$BUN_INSTALL,$PYTHONUSERBASE}/bin
        $PNPM_HOME
        {"$XDG_DATA_HOME",/var/lib}/flatpak/exports/bin
    )
    dir_pref_after=(
        /usr{/local,}/bin
    )
    essentials='/usr/bin'
    INIT_PATH="${PATH-}"
    __pathmunge
)"
export XDG_DATA_DIRS="$(
    dir_pref_before=(
        "$XDG_DATA_HOME"
        "$VLK_NIX_HOME/share"
        {"$XDG_DATA_HOME",/var/lib}/flatpak/exports/share
    )
    dir_pref_after=(
        /usr{/local,}/share
    )
    essentials=/usr/share
    INIT_PATH="${XDG_DATA_DIRS-}"
    __pathmunge
)"

unset -f __pathmunge
unset ICON_TYPE i j

if [[ -n ${VTE_VERSION-} || $TERM =~ (kitty|alacritty|foot) ]] {
    export ICON_TYPE=dashline
} else {
    export ICON_TYPE=fallback
}

fpath=("$ZDOTDIR/site-functions" $fpath)
export -U PATH path FPATH fpath
export -U XDG_DATA_DIRS
typeset -Ug chpwd_functions
typeset -Ug precmd_functions
typeset -Ug module_path
