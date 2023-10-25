#!/usr/bin/bash
# script to install my dotfiles on a distro. Not meant to be comprehensive or anything
# This script is only intended for me to use. It does not install any dependencies.

# bash unofficial strict mode with my own extensions
set -euo pipefail
TAB=$'\t' LF=$'\n' IFS="$LF$TAB" READNULLCMD=''
printf '\e[0m\e[2J\e[H\e[m' # clear screen

_panic() {
    [[ ${1:-} == '--nice' ]] && local _p_retval=0 && shift 1
    printf '%s\n\e[0m' "$@" >&2
    exit "${_p_retval:-1}"
}
# check for dependencies, set the pager
declare -a faildeps=()
for i in "${PAGER:=less}" mkdir mv ln realpath sed; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Missing dependencies:" "${faildeps[@]}" "confused? Try out 'https://command-not-found.com'"

[[ ${*:-} == *d* ]] && DRY_RUN=1
[[ ${*:-} == *f* ]] && FORCE=1

# this script will not work unless you are in the homescripts dir
[[ "$(<"$PWD/.git/config")" == *'github.com/REALERvolker1/homescripts'* ]]

# find non-duplicate backup folder for all the old files
for ((i=0;i++<999;)){ [ ! -e "$HOME/oldskel_$i" ] && preserve_dir="$HOME/oldskel_$i" && break;}

# don't symlink these dirs
declare -A skips=(
    [".local/share/flatpak"]=1
)
# queue file operations, and make searchable hash
declare -a queue=("mkdir:$preserve_dir")
declare -A make_dirs=([$preserve_dir]=1)

# since searchable hashes and skips may be empty, skip checking undefined variables
set +u
for i in ./bin ./.config/* ./.local/share/* .profile; do
    base="${i#*/}"
    source="$PWD/$base"
    dest="$HOME/$base"
    preserve="$preserve_dir/$base"

    ((${FORCE:=0})) || [[ "$(realpath "$source")" != "$(realpath "$dest")" ]] || continue
    ((${skips[$base]})) && echo "skipping override $dest" && continue

    for j in "${dest%/*}" "${preserve%/*}"; do
        ((${make_dirs[$j]})) && continue
        make_dirs[$j]=1
        queue+=("mkdir:$j")
    done
    [[ -e $dest ]] && queue+=("mv:$dest${TAB}$preserve")
    queue+=("ln:$source${TAB}$dest")
done
set -u

printf '%s\n' "${queue[@]}" | sed -E "s/^([^:]+):/[1m\1[0m:/" | $PAGER $([[ $PAGER == less ]] && echo '-r')

((${DRY_RUN:=0})) && _panic --nice 'dry run completed'
read -r -p "${LF}Do you want to install these dotfiles? [y/N] > " ans
[[ ${ans:-} == y ]] || _panic --nice 'skipping install'

for i in "${queue[@]}"; do
    i_tmp="${i#*:}"
    source="${i_tmp%%$TAB*}"
    dest="${i_tmp##*$TAB}"
    case "${i%%:*}" in
    mkdir) mkdir -p "$source" && echo "ensured directory $source" ;;
    mv) mv "$source" "$dest" && echo "moved '$source' to '$dest'" ;;
    ln) ln -s "$source" "$dest" && echo "symlinked '$source' to '$dest'" ;;
    esac
done
