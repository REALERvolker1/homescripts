#!/usr/bin/bash
set -euo pipefail

SUDO='echo sudo'
_boot_cfg() {
    local file fp entry_str i
    local -i MAX_BACKUP_FILES=99999
    local -a modules
    local -a current
    local -A strcfg

    case "${1:-}" in
    --grub)
        file="$HOME/code/xerolinux/test/test.txt"
        entry_str='GRUB_CMDLINE_LINUX_DEFAULT'
        strcfg=([start]='"' [end]='"' [prefix]='' [comment]='#')
        modules=('rd.driver.blacklist=nouveau' 'modprobe.blacklist=nouveau' 'nvidia-drm.modeset=1')
        ;;
    --mkinitcpio)
        file="$HOME/code/xerolinux/test/test.txt"
        entry_str='MODULES'
        strcfg=([start]='(' [end]=')' [prefix]="\\" [comment]='#')
        modules=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
        ;;
    *) return 1 ;;
    esac
    current=($(grep -oP "^${entry_str}=${strcfg[prefix]}${strcfg[start]}\\K[^${strcfg[prefix]}${strcfg[end]}]*" "$file" || :))

    local -a new
    case "${2:-}" in
    --install)
        # take everything, if it isn't already in the flags, put it in the flags
        for i in "${modules[@]}" "${current[@]}"; do
            [[ "${new[*]}" != *"${i:-x}"* ]] && new+=("${i:-}")
        done
        ;;
    --remove)
        # if the flag is NOT in the nvidia flags, then add it to the list
        for i in "${current[@]}"; do
            [[ "${modules[*]}" != *"${i:-x}"* ]] && new+=("${i:-}")
        done
        ;;
    *) return 1 ;;
    esac

    if [[ "${current[*]}" == "${new[*]}" ]]; then
        echo "Skipping -- modules already installed"
        return
    fi

    local module_string="${entry_str}=${strcfg[start]}${new[*]}${strcfg[end]}"

    # Make backup of current
    for ((i = 0; i <= MAX_BACKUP_FILES; i++)); do
        fp="${file}.${i}.bak"
        [[ -e "$fp" ]] && continue # skip creation if backup file already exists
        $SUDO cp "$file" "$fp"
        break
    done

    # comment out old lines, read the rest to an array
    local -a file_contents
    while IFS= read -r line; do
        [[ "$line" == "$entry_str"* ]] && line="${strcfg[comment]}$line"
        file_contents+=("$line")
    done <"$file"

    local -a file_arr
    local -i has_replaced=0

    for i in "${file_contents[@]}"; do
        file_arr+=("$i")
        ((has_replaced)) && continue
        if [[ "$i" == "${strcfg[comment]}$entry_str"* ]]; then
            file_arr+=("$module_string")
            has_replaced=1
        fi
    done
    # handle if it had empties
    ((has_replaced)) || file_arr+=("$module_string")

    $SUDO printf '%s\n' "${file_arr[@]}" >"$file"
}

# cp -f "${file%/*}/lmao.txt" "$file"
_boot_cfg "$@"
