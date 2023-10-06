#!/usr/bin/bash
set -euo pipefail
current_dir="$PWD"

if [[ ! -d "${HOMESCRIPTS:-}" ]]; then
    echo "Error, directory '${HOMESCRIPTS:-}' does not exist!"
    return 1
fi

git_interact() {
    local default commitmsg
    default="$(date +"Commit from ${0##*/} at %D %r")"
    cd "$HOMESCRIPTS"
    case "${1:-}" in
    'commit')
        echo -en "What would you like the commit message to say?
(enter 'q' or 'exit' to quit, leave blank to print default)
$default
> "
        read -r commitmsg
        case "${commitmsg:-}" in
        q | quit | exit)
            echo "Exiting..."
            return 1
            ;;
        '')
            commitmsg="$default"
            ;;
        esac
        git add -A
        git commit -am "$commitmsg"
        ;;
    'push') git push ;;
    'diff')
        git fetch
        git diff "origin/$(git branch | grep -oP "\*[[:space:]]*\K.*\$")"
        ;;
    *) echo 'Error, please specify a git action to take on dotfiles' ;;
    esac
    cd "$current_dir"
}

dotadd() {
    local symlink dotfolder linkfolder
    dotfolder="${1:?Error, please choose a folder!}"
    dotfolder="$(realpath -e "$dotfolder")"
    [[ -e "$dotfolder" ]]

    case "$dotfolder" in
    "$HOME/"*)
        symlink=true
        linkfolder="$HOMESCRIPTS/${dotfolder//$HOME/}"
        ;;
    *)
        symlink=false
        linkfolder="$HOMESCRIPTS/disk-root${dotfolder}"
        ;;
    esac
    mkdir -p "${linkfolder%/*}"
    if $symlink; then
        mv -i "$dotfolder" "$linkfolder"
        ln -si "$linkfolder" "$dotfolder"
    else
        cp -ri "$dotfolder" "$linkfolder"
    fi
}
action="${1:-}"
shift 1
case "${action:-}" in
'--git')
    git_interact "$@"
    ;;
'--dotadd')
    dotadd "$@"
    ;;
*)
    echo "Error, please select one of '--git' or '--dotadd'!"
    exit 1
    ;;
esac
