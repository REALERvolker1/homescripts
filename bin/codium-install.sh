#!/bin/sh
# script by vlk to install vscodium on any linux distro
set -eu

# path to install it to
codium_path="$HOME/.local/opt/codium"

# internals
codium_version_prefix='VSCodium-linux-x64'
codium_version_suffix='tar.gz'
codium_id='VSCodium/vscodium'
codium_data="$codium_path/data"
codium_version_file="$codium_data/current-version.txt"
codium_tgz="$codium_path/codium.tar.gz"

# check dependencies
for i in \
    'jq' \
    'curl' \
    'lsof'; do
    #'gh' \
    if command -v "$i" >/dev/null; then
        true
    else
        echo "Error, dependency '$i' was not found!"
        exit 1
    fi
done

# ensure datafiles
[ ! -d "$codium_data" ] && mkdir -p "$codium_data"
[ ! -f "$codium_version_file" ] && touch "$codium_version_file"

# argparse
force=0
check=0
help=0
for i in "$@"; do
    case "${i:-}" in
    '--force' | '-f')
        force=1
        ;;
    '--check' | '-c')
        check=1
        ;;
    *)
        help=1
        ;;
    esac
done
if [ "$help" -eq 1 ]; then
    printf '%s\n' \
        "${0##*/} --arg --here" \
        '' \
        '--force, -f   force update' \
        '--check, -c   check for updates (do not install)'
    exit 1
fi

trykill_codium() {
    if [ "$(lsof +D "$codium_path")" = "" ]; then
        echo "codium directory is not in use. Continuing"
    else
        echo "You have codium open right now! Want me to try and kill it?"
        printf '[y/n] > '
        read -r answer
        if [ "$answer" = 'y' ]; then
            killall codium
            sleep 1
            if [ "$(lsof +D "$codium_path")" != "" ]; then
                echo "Error, killing codium did not unlock the directory. Updates cannot be completed."
                exit 1
            fi
        else
            echo "Aborting update"
            exit 1
        fi
    fi
}

# exit if no connection to github
if ! curl -sf -H 'Accept: application/vnd.github+json' 'https://api.github.com/' >/dev/null; then
    echo "Error, could not connect to github"
    exit 1
fi
# get the latest release url
release_url="$(
    curl -s -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/$codium_id/releases/latest" |
        jq -r ".assets | .[] | \
            select(.name | startswith(\"$codium_version_prefix\")) | \
            select(.name | endswith(\"$codium_version_suffix\")) | \
            .browser_download_url" |
        head -n 1
)"
installed_version="$(cat "$codium_version_file")"
release_version="${release_url##*/}"

if [ "$installed_version" = "$release_version" ]; then
    printf '%s\n' \
        "You are already up to date!" \
        "$release_version"
    # stop if they don't want to force an update
    if [ "$force" -eq 0 ]; then
        exit 0
    fi
else
    # updates found
    printf '%s\n' \
        "want to update codium?" \
        "current:  $installed_version" \
        "new:      $release_version"
    if [ "$force" -eq 0 ]; then
        answer=''
        printf '[y/n] > '
        read -r answer
        [ "$answer" = 'y' ] || exit 1
    fi
fi
# stop if they only wanted to check
[ "$check" -eq 1 ] && exit 0

# install updates
trykill_codium
[ -e "$codium_tgz" ] && rm "$codium_tgz"
# wget -O "$codium_tgz" "$release_url"
curl -Lo "$codium_tgz" "$release_url"

trykill_codium
echo '
extracting files...'
tar -xzf "$codium_tgz" --overwrite -C "$codium_path"

echo "$release_version" >"$codium_version_file"

if [ ! -e "$HOME/.local/bin/codium" ]; then
    ln -s "$codium_path/bin/codium" "$HOME/.local/bin/codium"
fi
if [ ! -e "$HOME/.local/share/applications/codium.desktop" ]; then
    printf '%s\n' \
        '[Desktop Entry]' \
        'Name=VSCodium (portable)' \
        'Comment=Code Editing. Redefined.' \
        'Exec=codium' \
        'Icon=codium' \
        'Categories=TextEditor;Development;IDE;' \
        'MimeType=text/plain;application/x-codium-workspace;' \
        'Keywords=vscode;' \
        'Type=Application' \
        'StartupNotify=false' >"$HOME/.local/share/applications/codium.desktop"
fi

if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium" ]; then
    mkdir -p "$codium_data/user-data"
    ln -s "$codium_data/user-data" "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium" || true
fi

echo "
successfully updated vscodium"
