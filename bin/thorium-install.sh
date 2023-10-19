#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

# name of the pkg
name='thorium'
# author/project name of the github repo
githubrepo='Alex313031/thorium'
# the output archive file
payload='thorium-browser*amd64.zip'
# the decompression command
decompresscmd='unzip -o'
# commands needed to install package, run in the installation directory
cmds="sed -i 's|^Exec=\./|Exec=|g ; s|^Icon=.*|Icon=thorium|' ./thorium-portable.desktop
for i in \$(pwd)/product_logo_*.png; do
i_int=\"\${i%.*}\"; i_int=\"\${i_int##*_}\"
i_folder=\"$XDG_DATA_HOME/icons/hicolor/\${i_int}x\${i_int}/apps\"
mkdir -p \"\$i_folder\"
ln -s \"\$i\" \"\${i_folder}/thorium.png\"
done"
# files to install (symlink target*destination/)
declare -a links=(
    "thorium*$HOME/.local/bin/thorium-browser"
    "thorium-portable.desktop*${XDG_DATA_HOME:=$HOME/.local/share}/applications/"
)

_panic() {
    local -i retval=1
    if [[ ${1:-} == '--nice' ]]; then
        retval=0
        shift 1
    fi
    printf '%s\n' "$@"
    exit "${retval:-1}"
}
declare -a faildeps=()
for i in jq curl lsof mkdir head rm cp mv; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
case "${1:-}" in
'') : ;;
'--force' | '-f') force=0 ;;
'--check' | '-c') check=1 ;;
*) _panic --nice "${0##*/} [--force (-f) OR --check (-c)]" ;;
esac
((${#faildeps[@]})) && _panic "Missing dependencies:" "${faildeps[*]}"

# internal
installdir="$HOME/.local/opt/$name"
versionfile="${XDG_CACHE_HOME:-$HOME/.cache}/vlk-install/${name}.version"
mycache="${XDG_CACHE_HOME:-$HOME/.cache}/vlk-install/$name"
# lockfile="${XDG_RUNTIME_DIR:-/tmp}/${0}-$name.lock"

mkdir -p "$installdir" "$mycache"
[[ -n "$(lsof +D "$installdir")" ]] && _panic "Error, $name appears to be running!"
curl -sf 'https://api.github.com/' >/dev/null || _panic "Error, could not connect to github"

release_url="$(
    curl -sL -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$githubrepo/releases/latest" |
        jq -r ".assets | .[] | \
            select(.name | startswith(\"${payload%%\**}\")) | \
            select(.name | endswith(\"${payload##*\*}\")) | \
            .browser_download_url" | head -n 1
)"
[[ ! -f "${versionfile:-}" ]] && true >"$versionfile"
installed_version="$(cat "$versionfile" || :)"
release_version="${release_url##*/}"

[[ "${installed_version:=Undefined}" == "${release_version:-}" ]] &&
    ((${force:-1})) &&
    _panic --nice "You are already up to date! ($release_version)"

echo -e "\e[0m\nDo you want to \e[92mupdate\e[0m \e[1m${name}\e[0m?\n"
echo -e "\e[0;1;31m$installed_version\e[0m => \e[0;1;32m$release_version\e[0m"
((${check:-0})) && _panic --nice "update check complete"
echo -en '[\e[0;1my\e[0m|\e[1mN\e[0m] > \e[1m'
read -r answer
echo -e '\e[0m'
[[ ${answer:-} == 'y' ]] || _panic --nice "User skipped update"

if [[ -e "${mycache:-}" ]]; then
    rm -rf "$mycache" || _panic "Error, failed to clear cache!"
fi
mkdir -p "$installdir" "${installdir}.bak"
payloadfile="$mycache/${payload//\*/+}"

cd "$mycache" || _panic "Failed to change working directory to $mycache"
curl -Lo "$payloadfile" "$release_url"

eval "$decompresscmd '$payloadfile'" || _panic "user decompression command failed!" "$decompresscmd"

rm -f "$payloadfile"
if [[ "$(printf '%s\n' "$installdir"/*)" != "$installdir/*" ]]; then
    cp -rf "$installdir"/* "${installdir}.bak"
fi
mv -f "$mycache"/* "$installdir"
echo "$release_version" >"$versionfile"

# run user build/install commands
cd "$installdir" || _panic "Failed to change working directory to $installdir"
echo "Building..."
# eval "$(printf '%s\n' "${cmds[@]}")"
# parsedcmds="${cmds//\*PWD\*/$PWD}"
echo "${cmds:=echo}"
eval "$cmds"
echo "Installing..."
for i in "${links[@]}"; do
    i_file="$installdir/${i%%\**}"
    i_dest="${i#*\*}"
    mkdir -p "${i_dest%/*}"

    ln -sf "$i_file" "$i_dest" && echo "installed $i_file to $i_dest"
done
