#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

SAVEDIR="${XDG_CONFIG_HOME:-$HOME/.config}/gsettings-sh"

# must have the / at the end
# "/ca/desrt/dconf-editor/"
save_paths=(
    "/org/cinnamon/desktop/media-handling/"
    "/org/gnome/desktop/interface/"
    "/org/gnome/file-roller/"
    "/org/gnome/nm-applet/"
    "/org/gtk/settings/file-chooser/"
    "/org/nemo/preferences/"
    "/org/xfce/mousepad/preferences/"
)

_load () {
    local filename contents current_path schema line i success_count fail_count
    for i in "$SAVEDIR/"*; do
        schema="${i##*/}"
        schema="${schema//%/\/}"
        #schema="${schema:1:-1}"
        success_count=0
        fail_count=0
        for line in $(cat "$i"); do
            if [[ "$line" == '['*']' ]]; then
                current_path="$(echo "$schema/${line:1:-1}/" | tr -s '/' '.' | grep -oP '^\.\K.*(?=\.$)')"
                gsettings list-children &>/dev/null || continue
                echo -e "$current_path"
            else
                if gsettings set "$current_path" "${line%%=*}" "${line#*=}"; then
                    success_count=$((success_count + 1))
                else
                    fail_count=$((fail_count + 1))
                fi
            fi
        done
        echo "Keys set: $success_count, Errors, $fail_count"
    done
}

_save () {
    local filename contents dir_content i
    dir_content="$(printf '%s\n' "$SAVEDIR/"*)"
    #printf '%s\n' "$SAVEDIR/"* | grep -qv '%'
    if echo "$dir_content" | grep -qv '%'; then
        # There are probable user files
        echo "$dir_content"
        printf "Are you sure you want to remove \e[1mALL\e[0m files in '${SAVEDIR}'? [y/N] "
        read -r answer
        case "$answer" in
            'y') echo ;;
            *) return 0 ;;
        esac
    fi
    rm "$SAVEDIR/"*

    echo -e "\n\e[1m\$\e[36mSAVEDIR\e[0m is \e[32m$SAVEDIR\e[0m\n"
    for i in "${save_paths[@]}"; do
        contents="$(dconf dump "$i")"
        [ -z "${contents:-}" ] && continue

        filename="$SAVEDIR/${i//\//%}"
        echo "$contents" > "$filename"
        echo -e "\e[92m$i\e[0m => \e[1m${filename/$SAVEDIR/\$\\e[36mSAVEDIR\\e[35m}\e[0m"
    done
}

operation="${1:-}"
case "$operation" in
    '--load')
        _load
        ;;
    '--save')
        _save
        ;;
    *)
        echo "Error, please select a task, either --load or --save"
        exit 1
        ;;
esac
