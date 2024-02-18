#!/usr/bin/env bash
# A script by vlk to automate interaction with systemd-boot

# Print an error message, then exit. For known points of failure
_panic() {
    printf '%s\n' "$@"
    exit 1
}

# get the root fs
# The first form just matches all non-spaces after UUID=, and then only matches on lines for the / partition
#root=$(grep -oP '^UUID=\K[^\s]+(?=\s+/\s+)' /etc/fstab)
# The other one actually matches UUIDs, but could be buggy on some hardware
#root=$(grep -oP '^UUID=\K[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}(?=\s+/\s)' /etc/fstab)
root=$(grep -oP '^UUID=\K[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}(?=\s+/\s)' /etc/fstab)
[[ -n ${root-} ]] || _panic "Error, root UUID '$root' is invalid!"

# set the kernel cmdline
# having this as an array makes it a bit more ergonomic and readable
declare -a sdb_options=(
    "root=UUID=$root" rw zswap.enabled=0 nowatchdog nvme_load=yes
    rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1
    modprobe.blacklist=iTCO_wdt
)
# intel_pstate=passive kernel.split_lock_mitigate=0

# set this option to 1 if you are using mkinitcpio to generate stuff, 0 to disable
declare -i MKINITCPIO=1

# bootloader conf options
LOADER_DEFAULT_TIMEOUT=1
LOADER_DEFAULT_CONSOLE_MODE=max

# Set your bootctl install path. Should be automatic, but you can manually set it if this is broken
# The following are default values
#BOOT_PATH=/boot
#LOADER_PATH="$BOOT_PATH/loader"
#ENTRIES_PATH="$LOADER_PATH/entries"

# Asks the user a yes or no question, with a prompt. Can change which answer is given by default
_prompt() {
    local promptstr='[Y/n]'
    local -i default_retval=0
    if [[ "${1:-}" == -n ]]; then
        shift 1
        promptstr='[y/N]'
        default_retval=1
    fi

    # non-interactive mode breaks prompts
    ((INTERACTIVE)) || return $default_retval

    (($#)) && printf '%s\n' "$@"
    local ans
    read -r -p "$promptstr > " ans

    # set it to blank if unset, set all lowercase
    ans="${ans-}"
    ans="${ans,,}"

    if [[ $ans == y ]]; then
        return 0
    elif [[ -z $ans ]]; then
        # empty, it is using the defaults
        return $default_retval
    else
        return 1
    fi
}

# Generates config file content from the autodetected entries. This is filename-based
# Side effects: populates array $generated_configs
_generate_configs() {
    # Make sure we have entries
    local vml irfs base name file contents
    # find all the imgs that correspond to the kernel img
    local -a vmlinuz=("$BOOT_PATH/vmlinuz"*)

    # If there is only one kernel installed, there's no point in waiting
    local -i num_vmlinuz="${#vmlinuz[@]}"
    if ((num_vmlinuz > 1)); then
        echo "There is only '$num_vmlinuz' kernel. removing loader timeout"
        LOADER_DEFAULT_TIMEOUT=0
    fi

    for vml in "${vmlinuz[@]}"; do
        base="${vml#*/vmlinuz-}"
        # All initramfs will have a vmlinuz kernel thingy. fallback initramfs will use the same kernel as the regular.
        for irfs in "$BOOT_PATH/initramfs-$base"{,-fallback}.img; do
            if [[ -f $irfs ]]; then
                name="${irfs##*/initramfs-}"
                name="${name%.img}"

                file="$ENTRIES_PATH/$name.conf"

                printf -v contents '%s\t%s\n' \
                    title "$name" \
                    linux "${vml##*/}" \
                    initrd "${irfs##*/}" \
                    options "$SDB_OPTIONS"

                generated_configs["$file"]="$contents"
            fi
        done
    done

    # set the contents of loader.conf to good defaults if it does not exist
    # Don't set the default entry, let the user select
    file="$LOADER_PATH/loader.conf"
    if [[ ! -f "$file" ]]; then
        printf -v contents '%s\t%s\n' \
            timeout "$LOADER_DEFAULT_TIMEOUT" \
            console-mode "$LOADER_DEFAULT_CONSOLE_MODE" \
            editor no

        generated_configs["$file"]="$contents"
    fi
}

# helper function to print a bit of text in bold
__bolded() {
    local prepend="\e[0;1m"
    local append="\e[0m"
    if [[ ${1-} == --header ]]; then
        shift 1
        prepend="\n$prepend"
        append="$append\n"
    fi
    local text="${1:?Error, no text to make bold!}"

    echo -e "${prepend}${text}${append}"
}

# helper text to print a config from generated configs
__print_config() {
    local conf="${1:?Error, no config file selected!}"
    __bolded "$conf"
    echo "${generated_configs[$conf]}"
}

# print all the configs that were generated, or generate some if there were none. Also prints all the current loaded configs
_print_configs() {
    __bolded --header '=== CURRENT ==='
    bootctl list --no-pager
    __bolded --header '=== DETECTED ==='

    local file contents
    for file in "${!generated_configs[@]}"; do
        __print_config "$file"
    done
}

_apply_configs() {
    if ((INTERACTIVE)); then
        _print_configs
        _prompt -n "Do you want to install these systemd-boot config files?" \
            'sudo required' || _panic "Chose not to install"
    fi

    # make sure both folders exist
    sudo mkdir -p "$ENTRIES_PATH"
    sudo mkdir -p "$ENTRIES_PATH.bak"
    sudo mv -f "$ENTRIES_PATH"/* "$ENTRIES_PATH.bak" || :

    if ((MKINITCPIO)) && _prompt "Want to run 'mkinitcpio -P' to generate?"; then
        sudo mkinitcpio -P
    fi

    sudo bootctl cleanup
    for file in "${!generated_configs[@]}"; do
        sudo touch -- "$file"
        echo "${generated_configs[$file]}" | sudo tee "$file"
    done

    # This command will fail unless run right after a systemd package update
    sudo bootctl update || :

    _ensure_default
}

# Make sure there is a default entry to boot into
_ensure_default() {
    local path selection default_entry i file
    # the path to the default listed
    path=$(bootctl list --json=short | jq -r '.[] | select(.isDefault == true).path')

    # if the default option was deleted or something, the path will point to efivars
    # This figures out if it should be reset
    [[ $path == "$ENTRIES_PATH"* && ${1-} != --override ]] && return 0

    if ((INTERACTIVE)); then
        __bolded "Current default entry"
        __print_config "$path"

        local -a entries=()
        local count=0
        for i in "$ENTRIES_PATH"/*; do
            count=$((count + 1))
            entries+=("$i")
        done
        local sel
        local prompt_str=$'\n'"[0-${#entries[@]}] > "
        while true; do
            __bolded --header "Please select a new default boot entry"
            for i in "${!entries[@]}"; do
                # I am doing i + 1 because starting from zero is awkward for humans
                printf '[ \e[1m%s\e[0m ] %s\n' $((i + 1)) "${entries[$i]}"
            done
            read -r -p "$prompt_str" selection

            # You are supposed to select a path by number
            case "${selection:-}" in
            '' | *[!0-9]*)
                echo "Invalid selection! Please choose a number!"
                continue
                ;;
            esac

            # reconvert it to array bounds
            selection=$((selection - 1))

            sel="${entries[$selection]:-}"
            if [[ -f $sel ]]; then
                default_entry="$sel"
                break
            else
                echo "Invalid path!"
            fi
        done
    else
        # select a random entry. This is only if it was called automatically and the current default is not real
        for file in "${!generated_configs[@]}"; do
            if [[ $file != *'-fallback'* ]]; then
                # skip fallback entries. They are supposed to be for debugging or whatever
                default_entry="$file"
                break
            fi
        done
    fi

    # unable to find one
    [[ -f ${default_entry-} ]] || _panic "Error, unable to ensure a default systemd-boot path! Please run this script manually!" "$0" "Expected real entry path, got '${default_entry-}'"

    sudo bootctl set-default "${default_entry##*/}"

    # This command will fail unless run right after a systemd package update
    sudo bootctl update || :
}

_argparse() {
    local arg action
    if (($#)); then
        for arg in "$@"; do
            shift 1
            case "${arg:=}" in

            show-entries)
                action=print
                ;;
            set-default)
                action=set_default
                ;;
            update)
                action=update
                ;;

            --no-interactive | -y)
                INTERACTIVE=0
                ;;
            --no-mkinitcpio)
                MKINITCPIO=0
                ;;

            *)
                _help
                _panic "Invalid argument: '$arg'"
                ;;
            esac
        done
    else
        # no args were passed, just run status
        bootctl status --no-pager
    fi
    case "${action:=}" in
    print)
        _print_configs
        ;;
    set_default)
        _ensure_default --override
        ;;
    update)
        _apply_configs
        ;;
    *)
        _help
        _panic 'No action selected!'
        ;;
    esac
}

_help() {
    echo "${0##*/} [--options] SUBCOMMAND

Available options:
  --no-interactive (-y)   Manually disable interactive mode. Useful for scripts
  --no-mkinitcpio         Disable mkinitcpio. Useful for scripts. Only works if MKINITCPIO is set to 1

Available subcommands:
  show-entries            Show all the entries the script can detect
  set-default             Set the default entry (one that the script can detect)
  update                  Update the list of entries


Most config options are set by editing the script itself, located at
$0
"
}

# Main script begins

# safe mode. Do not remove
set -euo pipefail

# set the options into a scalar var for simplicity
IFS=' '
SDB_OPTIONS="${sdb_options[*]}"
IFS=$'\n\t'

# dependency check
declare -a faildeps=()
for i in bootctl jq whoami tee touch mkdir sudo; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependency commands:" "${faildeps[@]}"

# load default values for config
LOADER_DEFAULT_TIMEOUT="${LOADER_DEFAULT_TIMEOUT:-5}"
LOADER_DEFAULT_CONSOLE_MODE="${LOADER_DEFAULT_CONSOLE_MODE:-keep}"

BOOT_PATH="${BOOT_PATH:-$(bootctl --print-boot-path)}"
LOADER_PATH="${LOADER_PATH:-$BOOT_PATH/loader}"
ENTRIES_PATH="${ENTRIES_PATH:-$LOADER_PATH/entries}"

MKINITCPIO=${MKINITCPIO:-0}

# Uses sudo for all escalation. This script is not root-safe
[[ $(whoami) == root ]] && _panic "Error, this script must not be run as root!"

declare -i INTERACTIVE=0
if [[ -t 0 && -t 1 && -t 2 ]]; then
    # interactive stdin, stdout, stderr
    INTERACTIVE=1
fi

# Make sure all the paths are where they need to be
[[ -d $BOOT_PATH ]] || _panic "Error, boot path '$BOOT_PATH' does not exist!"
[[ -d $LOADER_PATH ]] || panic "Error, bootloader path '$LOADER_PATH' does not exist!"

# The global array for all config files found by the script
declare -A generated_configs=()

# the entries path could be empty or not exist on a fresh install
if ! _generate_configs; then
    if _prompt -n "No boot entries were found. Want to autodetect and install?"; then
        _apply_configs
    else
        _panic "No boot entries, install failed"
    fi
fi

_argparse "$@"
