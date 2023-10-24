#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

_panic() {
    local -i retval=1
    if [[ ${1:-} == '--nice' ]]; then
        retval=0
        shift 1
    fi
    printf '%s\n' "$@"
    exit "${retval:-1}"
    # return "${retval:-1}"
}

_icon_install() {
    # resizes icons to a specific size and then installs them
    local icon="${1:-}"
    local icon_name="${2:-}"
    [[ ! -f "$icon" ]] && _panic "Error, specified icon '$icon' does not exist!"
    [[ -z "${icon_name:-}" ]] && icon_name="${icon##*/}"

    local i i_target
    for i in 16 24 32 48 64 128 256; do
        i_target="$XDG_DATA_HOME/icons/hicolor/${i}x${i}/apps/$icon_name"
        mkdir -p "${i_target%/*}"
        [[ -f "$i_target" ]] && continue
        convert "$icon" -resize "${i}x${i}" "$i_target"
    done
}

_install_package() {
    local installfile="${1:-}"
    [[ ! -f $installfile ]] && _panic "Error, failed to install '$installfile'"
    echo "${installfile##*/}"
    unset name githubrepo payload decompresscmd cmds
    source "$installfile" || _panic "Failed to source $installfile"

    local i
    # double check user installfile
    # eval "$(
    #     for i in name githubrepo payload decompresscmd cmds; do
    #         echo "[[ -z \"\${$i:-}\" ]] && _panic 'Error, variable $i not properly defined!'"
    #     done
    # )"

    # internal variables per-package
    local installdir="$HOME/.local/opt/$name"
    local versionfile="${XDG_CACHE_HOME:-$HOME/.cache}/vlk-install/${name}.version"
    local mycache="${XDG_CACHE_HOME:-$HOME/.cache}/vlk-install/$name"
    # lockfile="${XDG_RUNTIME_DIR:-/tmp}/${0}-$name.lock"

    # remove cached installations
    if [[ -e "${mycache:-}" ]]; then
        rm -rf "$mycache" || _panic "Error, failed to clear cache!"
    fi
    mkdir -p "$installdir" "$mycache"
    # make sure it is not running -- it would be bad if runtime was affected
    [[ -n "$(lsof +D "$installdir")" ]] && _panic "Error, $name appears to be open!"

    local release_url
    release_url="$(
        curl -sL -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$githubrepo/releases/latest" |
            jq -r ".assets | .[] | \
                select(.name | startswith(\"${payload%%\**}\")) | \
                select(.name | endswith(\"${payload##*\*}\")) | \
                .browser_download_url" | head -n 1
    )"
    [[ ! -f "${versionfile:-}" ]] && true >"$versionfile"
    local installed_version
    installed_version="$(cat "$versionfile" || :)"
    local release_version="${release_url##*/}"

    # exit if up to date
    [[ "${installed_version:=Undefined}" == "${release_version:-}" ]] &&
        ((${force:-1})) &&
        echo "You are already up to date! ($release_version)" && return

    echo -e "\e[0m\nDo you want to \e[92mupdate\e[0m \e[1m${name}\e[0m?\n"
    echo -e "\e[0;1;31m$installed_version\e[0m => \e[0;1;32m$release_version\e[0m"
    ((${check:-0})) && _panic --nice "update check complete" # exit if the user just wanted to check
    echo -en '[\e[0;1my\e[0m|\e[1mN\e[0m] > \e[1m'
    read -r answer
    echo -e '\e[0m'
    [[ ${answer:-} == 'y' ]] || _panic --nice "User skipped update" # consent
    [[ -e "${installdir}.bak" ]] && rm -rf "${installdir}.bak"
    mkdir -p "$installdir" "${installdir}.bak"
    local payloadfile="$mycache/${payload//\*/+}"

    cd "$mycache" || _panic "Failed to change working directory to $mycache"
    curl -Lo "$payloadfile" "$release_url"

    eval "$decompresscmd '$payloadfile'" || _panic "user decompression command failed!" "$decompresscmd"

    rm -f "$payloadfile"
    if [[ "$(printf '%s\n' "$installdir"/*)" != "$installdir/*" ]]; then
        cp -rf "$installdir"/* "${installdir}.bak"
    fi
    cp -rf "$mycache"/* "$installdir"

    echo "$release_version" >"$versionfile"

    # run user build/install commands
    cd "$installdir" || _panic "Failed to change working directory to $installdir"
    rm -rf "$mycache"
    echo "Running user commands"
    # eval "$(printf '%s\n' "${cmds[@]}")"
    # parsedcmds="${cmds//\*PWD\*/$PWD}"
    echo "${cmds:=echo}"
    eval "$cmds"
    # for i in "${links[@]}"; do
    #     i_file="$installdir/${i%%\**}"
    #     i_dest="${i#*\*}"
    #     mkdir -p "${i_dest%/*}"

    #     ln -sf "$i_file" "$i_dest" && echo "installed $i_file to $i_dest"
    # done
    echo -e "\tDone installing \e[1m$name\e[0m\n"
}

curl -sf 'https://api.github.com/' >/dev/null || _panic "Error, could not connect to github"
declare -a faildeps=()
for i in jq curl lsof mkdir head rm cp mv convert; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Missing dependencies:" "${faildeps[*]}" "confused? Try out 'https://command-not-found.com'"

[[ -z ${VLKINSTALL_HOME:-} ]] && VLKINSTALL_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/vlk-install"
# argparse
declare -a installpkgs
for i in "${@:-null}"; do
    case "${i:-}" in
    '--force' | '-f') force=0 ;;
    '--check' | '-c') check=1 ;;
    '--update' | '-u') update=1 ;;
    *)
        if [[ -f "$VLKINSTALL_HOME/$i.sh" ]]; then
            installpkgs+=("$VLKINSTALL_HOME/$i.sh")
        else
            _panic "${0##*/} [--force (-f) OR --check (-c)]"
        fi
        ;;
    esac
done

((${update:-0})) && installpkgs=("$VLKINSTALL_HOME"/*)

for i in "${installpkgs[@]}"; do
    [[ -r "$i" ]] && _install_package "$i"
done
# if ((${update:-0})); then
#     for i in "$VLKINSTALL_HOME/"*'.sh'; do
#         [[ -r "$i" ]] && _install_package "$i"
#     done
# fi
