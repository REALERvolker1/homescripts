#!/bin/dash
# script by vlk to manage git

GIT_DIR="${GITMGMT_SRC_HOME:-}"
SCRIPT_DIR="${GITMGMT_SCRIPT_HOME:-}"
#ASSETS_DIR="${GITMGMT_SCRIPT_HOME:-}/assets"

[ -z "$GIT_DIR" ] && echo "Error, please specify \$GITMGMT_SRC_HOME" && exit 1
[ -z "$SCRIPT_DIR" ] && echo "Error, please specify \$GITMGMT_SCRIPT_HOME" && exit 1

pull_git () {
    dir="$1"
    cd "$dir" || return 1
    pulled_dir="$(git pull)"
    #echo "$pulled_dir" 1>&2
    if [ "$pulled_dir" = 'Already up to date.' ] && [ "$force" -eq 0 ]; then
        return
        #echo "${dir##*/} is already up to date" 1>&2
    elif [ -x "$SCRIPT_DIR/${dir##*/}" ]; then
        echo "$pulled_dir" 1>&2
        echo "===${dir##*/}"
    else
        echo "$pulled_dir" 1>&2
    fi
}

pull_iter () {
    for i in "$GIT_DIR"/*; do
        pull_git "$i" &
    done
    wait
}

run_update_script () {
    name="$1"
    if cd "$GIT_DIR/$name"; then
        if [ -x "$SCRIPT_DIR/$name" ]; then
            echo "Running $SCRIPT_DIR/$name"
            sh -c "$SCRIPT_DIR/$name"
        else
            echo "Error: COuld not run script for $name"
        fi
    else
        echo "Error: Could not change directory to $GIT_DIR/$name"
    fi
}

execute_update () {
    echo "Getting updates..."
    pull_iter | grep -oP '===\K.*' | while read -r line; do
        run_update_script "$line"
    done
    echo "Done updating!"
}

execute_add () {
    echo "Do you want to add $PWD as a gitmgmt-managed directory? [y/n]"
    read answer
    if [ "$answer" = 'y' ]; then
        name="${PWD##*/}"
        touch "$SCRIPT_DIR/$name"
        chmod +x "$SCRIPT_DIR/$name"
        printf '#!/usr/bin/bash
[ "$PWD" != "$GITMGMT_SRC_HOME/${0##*/}" ] && exit 1
git sync -f
[ -d "$GITMGMT_SCRIPT_HOME/assets/${0##*/}" ] && cp -rf "$GITMGMT_SCRIPT_HOME/assets/${0##*/}/"* "$PWD"' > "$SCRIPT_DIR/$name"
        echo "Edit the file at $SCRIPT_DIR/$name"
    fi
}

force=0
case "$1" in
    '--force')
        force=1
        ;; '--add')
        execute_add
    ;; '--update')
        execute_update
    ;; *)
        printf "args:
--add\tAdd a folder to be tracked
--update\tUpdate your gits
"
    ;;
esac


