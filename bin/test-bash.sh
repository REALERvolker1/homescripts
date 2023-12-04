
set -euo pipefail
# INIT_PATH='/usr/local/bin:/usr/bin:/usr/local/sbin:/opt/cuda/bin:/opt/cuda/nsight_compute:/opt/cuda/nsight_systems/bin:/home/vlk/.dotnet/tools:/var/lib/flatpak/exports/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl'
# INIT_PATH='/usr/local/bin:/usr/bin:/usr/local/sbin:/bin:/lmao:/opt/cuda/bin:/sbin:/opt/cuda/nsight_compute:/opt/cuda/nsight_systems/bin:/home/vlk/.dotnet/tools:/var/lib/flatpak/exports/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/vlk/bin:/home/vlk/.local/bin:/home/vlk/.local/share/cargo/bin:/home/vlk/.local/share/go/bin:/home/vlk/.local/share/bun/bin:/home/vlk/.local/share/pnpm:/home/vlk/.local/share/python/bin:/home/vlk/.local/share/flatpak/exports/bin'

# # declare -a dir_pref_before=({"$HOME"{,.local},"$CARGO_HOME","$GOPATH","$PYTHONUSERBASE","$BUN_INSTALL","$XDG_DATA_HOME/flatpak/exports"}/bin "$PNPM_HOME")
# typeset -a dir_pref_before=(
#     "$HOME/bin"
#     "$HOME/.local/bin"
#     "$CARGO_HOME/bin"
#     "$GOPATH/bin"
#     "$BUN_INSTALL/bin"
#     "$PNPM_HOME"
#     "$PYTHONUSERBASE/bin"
#     "$XDG_DATA_HOME/flatpak/exports/bin"
# )

# typeset -a dir_pref_after=(
#     '/var/lib/flatpak/exports/bin'
#     '/usr/local/bin'
#     '/usr/bin'
# )

# if [[ -n ${BASH_VERSION-} ]]; then
#     _PATH="$(
#         declare -A __path
#         declare -a __bashpath
#         declare -i idx=0
#         for i in "${dir_pref_before[@]}"; do
#             i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
#             __path[$i]="$idx:$i"
#             idx+=1
#         done
#         while read -r -d ':' i; do
#             i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
#             if [[ -z ${__path[$i]-} ]]; then
#                 __path[$i]="$idx:$i"
#                 idx+=1
#             fi
#         done <<<"$INIT_PATH"

#         for i in "${dir_pref_after[@]}"; do
#             i="$([[ -d $i ]] && realpath -e "$i" 2>/dev/null)" || continue
#             __path[$i]="$idx:$i"
#             idx+=1
#         done
#         printf '%s\n' "${__path[@]}" | sort -n | cut -d ':' -f 2 | tr -s '\n' ':'
#     )"
# elif [[ -n ${ZSH_VERSION-} ]]; then
#     _PATH="${(@f)$(
#         typeset -aU __path=(${dir_pref_before:A} ${${(s.:.)INIT_PATH}:A})
#         typeset -aU __zshpath
#         for i in ${__path:|dir_pref_after} ${dir_pref_after:A}; do
#             [[ -d $i ]] && __zshpath+=($i)
#         done
#         echo "${(j.:.)__zshpath}"
#     )}"
# fi

# # TODO: skip pathmunge if pathmunge bin doesn't exist. This can cause UB in zsh
# # __vlkenv_pathmunge_bin="$XDG_CONFIG_HOME/shell/rustcfg/pathmunge/target/release/pathmunge"
# __vlkenv_pathmunge_bin="$XDG_CONFIG_HOME/rustcfg/pathmunge/target/release/pathmunge"
# if [ ! -x "$__vlkenv_pathmunge_bin" ]; then
#     if command -v cargo >/dev/null 2>&1; then
#         if expr "$-" : '.*i' >/dev/null; then
#             tgtdir="${__vlkenv_pathmunge_bin%/target*}"
#             lastpath="${PWD:-$(pwd)}"
#             if [ -d "$tgtdir" ]; then
#                 builtin cd "$tgtdir" || :
#                 cargo build --release
#                 builtin cd "$lastpath" || :
#             else
#                 echo "vlkenv pathmunge not found. falling back to default."
#             fi
#             unset tgtdir lastpath
#         else
#             echo "Not in interactive mode: Skipping building pathmunge"
#         fi
#     else
#         echo "Cargo not found. Skipping building pathmunge"
#     fi
#     __pathmunge_helper_function() {
#         case ":${pathlike}:" in
#         *":${1}:"*) true ;;
#         *) [ -d "$1" ] && tmppth="$1${tmppth:+:$tmppth}" ;;
#         esac
#     }
#     __pathmunge() {
#         pathlike=''
#         tmppth=''
#         for i in "$@"; do
#             case "${i:-}" in
#             '--pathlike='*)
#                 for j in $(echo "${i#*=}" | sed 's/:/ /g'); do
#                     __pathmunge_helper_function "$j"
#                 done
#                 ;;
#             *)
#                 __pathmunge_helper_function "$i"
#                 ;;
#             esac
#         done
#         echo "$tmppth"
#     }
#     __vlkenv_pathmunge_bin='__pathmunge'
# fi

# export XDG_DATA_DIRS="$(
#     $__vlkenv_pathmunge_bin \
#         "$XDG_DATA_HOME" \
#         "$XDG_DATA_HOME/flatpak/exports/share" \
#         '/var/lib/flatpak/exports/share' \
#         '/usr/local/share' \
#         '/usr/share' \
#         --pathlike="$XDG_DATA_DIRS"
# )"
# export PATH="$(
#     $__vlkenv_pathmunge_bin \
#         "$HOME/bin" \
#         "$HOME/.local/bin" \
#         "${CARGO_HOME:-ch}/bin" \
#         "${GOPATH:-gp}/bin" \
#         "${BUN_INSTALL:-bi}/bin" \
#         "${PNPM_HOME:-ph}" \
#         "${PYTHONUSERBASE:-pu}/bin" \
#         "$XDG_DATA_HOME/flatpak/exports/bin" \
#         '/var/lib/flatpak/exports/bin' \
#         '/usr/local/bin' \
#         --pathlike="$PATH" \
#         '/usr/bin'
# )"
# if [ "${__vlkenv_pathmunge_bin:-}" = '__pathmunge' ]; then
#     unset -f __pathmunge
#     unset -f __pathmunge_helper_function
# fi
# unset oldifs pathlike tmppth i j ICON_TYPE __vlkenv_pathmunge_bin
# PATH=":$HOME/bin:$HOME/.local/bin:${CARGO_HOME:-ch}/bin:${GOPATH:-gp}/bin:${PYTHONUSERBASE:-pu}/bin${PATH:+:$PATH}:/usr/local/bin:/usr/bin"

# for i in \
#     "$HOME/bin" \
#     "$HOME/.local/bin" \
#     "${CARGO_HOME:-ch}/bin" \
#     "${GOPATH:-gp}/bin" \
#     "${BUN_INSTALL:-bi}/bin" \
#     "${PNPM_HOME:-ph}" \
#     "${PYTHONUSERBASE:-pu}/bin" \
#     "$XDG_DATA_HOME/flatpak/exports/bin" \
#     '/var/lib/flatpak/exports/bin' \
#     '/usr/local/bin' \
#     '/usr/bin'; do
#     # [[ ":${PATH-}:" != *":$i:"* ]] && PATH="${PATH-}:$i"
#     PATH="${PATH-}:$i"
# done
# export PATH

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
        echo $hpath
    }
fi

INIT_PATH='/usr/local/bin:/usr/bin:/usr/local/sbin:/bin:/lmao:/opt/cuda/bin:/sbin:/opt/cuda/nsight_compute:/opt/cuda/nsight_systems/bin:/home/vlk/.dotnet/tools:/var/lib/flatpak/exports/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/vlk/bin:/home/vlk/.local/bin:/home/vlk/.local/share/cargo/bin:/home/vlk/.local/share/go/bin:/home/vlk/.local/share/bun/bin:/home/vlk/.local/share/pnpm:/home/vlk/.local/share/python/bin:/home/vlk/.local/share/flatpak/exports/bin'

# declare -a dir_pref_before=({"$HOME"{,.local},"$CARGO_HOME","$GOPATH","$PYTHONUSERBASE","$BUN_INSTALL","$XDG_DATA_HOME/flatpak/exports"}/bin "$PNPM_HOME")
typeset -a dir_pref_before=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$CARGO_HOME/bin"
    "$GOPATH/bin"
    "$BUN_INSTALL/bin"
    "$PNPM_HOME"
    "$PYTHONUSERBASE/bin"
    "$XDG_DATA_HOME/flatpak/exports/bin"
)
typeset -a dir_pref_after=(
    /var/lib/flatpak/exports/bin
    /usr/local/bin
    # /usr/bin
)
essentials='/usr/bin'

_PATH="$(__pathmunge)"

echo "$_PATH"

typeset -a dir_pref_before=(
    "$XDG_DATA_HOME"
    "$XDG_DATA_HOME/flatpak/exports/share"
)
typeset -a dir_pref_after=(
    /var/lib/flatpak/exports/share
    /usr/local/share
    /usr/share
)
essentials='/usr/share'
INIT_PATH="${XDG_DATA_DIRS-}"

_PATH="$(__pathmunge)"

echo "$_PATH"
