#!/usr/bin/env bash
# shellcheck shell=bash
# a script by vlk that installs nvidia drivers and other stuff on Fedora

#    Copyright (C) 2024  vlk (https://github.com/REALERvolker1)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Don't change this
set -euo pipefail
IFS=$'\n\t'

# The script name. Do not change
declare -r ME="${0##*/}"

# The path to the failed commands log file.
declare -r FAILED_COMMANDS_LOG="$HOME/$ME-failed-commands.log"

declare -a NVIDIA_PACKAGES NVIDIA_OPTIONAL_PACKAGES CODEC_PACKAGES CODEC_FFMPEG_PACKAGES

# TODO: Make this compatible with Arch
DISTRO=fedora

# Some formatting-related constants. Do not change these
declare -r LF=$'\n'
declare -r TAB=$'\t'
declare -r BOLD=$'\e[0;1m'
declare -r RESET=$'\e[0m'

# A function that prints lines of text in bold
util::bold() {
    printf '\e[0;1m%s\e[0m\n' "$@"
}

# Convert an array to a scalar, joining with spaces
util::join() {
    echo "$@"
}

# A consistent timestamp format
util::timestamp() {
    date +'%y-%m-%d_%H:%M:%S'
}

# Log a message to the console and wherever else I made it go.
# This function prints all arguments INLINE! using echo
util::log() {
    local log_level log_color
    case "${1:?Error, nothing to log!}" in
    --warn)
        shift 1
        log_level='WARN'
        log_color=$'\e[33m'
        ;;
    --error)
        shift 1
        log_level='ERROR'
        log_color=$'\e[36m'
        ;;
    --panic)
        shift 1
        log_level='PANIC'
        log_color=$'\e[31m'
        ;;
    *)
        log_level='INFO'
        log_color=$'\e[32m'
        ;;
    esac

    local -a args
    if (($#)); then
        args=("$@")
    else
        args=("$ME")
    fi

    printf "${BOLD}[ \e[0;36m$(util::timestamp)$BOLD ${log_color}${log_level}$BOLD ]$RESET %s${RESET}$LF" "${args[@]}" >&2
}

# A function to print an error message and then exit similar to `panic!()` in Rust
util::panic() {
    util::log --panic "$@"
    exit 1
}
util::log "$0"
util::panic "Error, this script is unfinished!"
# Prompt the user for a yes/no answer.
# When run with args, it will print the args as well as a prompt.
util::prompt() {
    (($#)) && printf '%s\n' "$@" ''

    local ans=''
    read -r -p "${RESET}[y/N] >${BOLD} " ans
    echo "$RESET"

    [[ "${ans^^}" == Y ]]
}

# Run a command. To run a command as root, use the --root flag as the first argument.
# If the command fails, it will log the command to $FAILED_COMMANDS_LOG
util::do() {
    local -a command
    local joined_command

    if [[ ${1:?Error, nothing to do!} == '--root' ]]; then
        shift 1
        local confirm=1
        if [[ "${1-}" == --noconfirm ]]; then
            shift 1
            confirm=0
        fi
        # Fedora uses sudo
        command=(sudo "$@")
        joined_command=$(util::join "${command[@]}")

        util::log --warn "Running command as root: $joined_command"

        if ! sudo -vn &>/dev/null; then
            if ((confirm)); then
                local oldifs="$IFS"
                local IFS=' '
                if ! util::prompt "Do you want to run the following command as root?" "$joined_command"; then
                    util::log --warn "Command run aborted by user!"
                    return 1
                fi
                IFS="$oldifs"
            fi
        fi
    else
        command=("$@")
        joined_command=$(util::join "${command[@]}")
    fi

    local retval=0

    # temporarily enter unsafe to get the return code without panicking
    set +e
    "${command[@]}"
    retval=$?
    set -e

    if ((retval)); then
        util::log --error "$joined_command" "Command failed with exit code $(util::bold "$retval")"
        if echo "${command[@]}" >>"$FAILED_COMMANDS_LOG"; then
            util::log --warn "Failed command was saved to $FAILED_COMMANDS_LOG"
        else
            util::panic "Failed to save failed command to $FAILED_COMMANDS_LOG"
        fi
    fi

    return $retval
}

check::installed() {
    local -a package_list=()
    if (($# > 1)); then
        local grep_string
        grep_string=$(util::join "$@")
        mapfile -t package_list < <(distro::pkglist | grep -E "(${grep_string// /|})")
    else
        mapfile -t package_list < <(distro::pkglist | grep "${1:?Error, no packages to check!}")
    fi

    local -i not_installed=1
    local package check
    for package in "$@"; do
        not_installed=1
        for check in "${package_list[@]}"; do
            if [[ "$package" == "$check" ]]; then
                not_installed=0
                break
            fi
        done
        if ((not_installed)); then
            return 1
        fi
    done
    return 0
}

# Create XDG directories (required for some parts of this script)
check::xdg_dirs() {
    for dir in \
        "${XDG_DATA_HOME:=$HOME/.local/share}" \
        "${XDG_CONFIG_HOME:=$HOME/.config}" \
        "${XDG_CACHE_HOME:=$HOME/.cache}" \
        "$HOME/.local/bin"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                util::log "Created directory: '$dir'"
            else
                util::panic "Failed to create directory: '$dir'"
            fi
        fi
    done
}

# Make sure the Fedora release is up-to-date and that this isn't running in the wrong mode in the wrong distro
check::fedora_release() {
    FEDORA_RELEASE=$(rpm -E %fedora)
    # Minimum Supported Fedora Release
    local -i msfr=39
    if ((FEDORA_RELEASE < msfr)); then
        util::panic "Unsupported old Fedora release: $FEDORA_RELEASE"
    elif ((FEDORA_RELEASE > msfr)); then
        util::log --warn "Your Fedora version ($FEDORA_RELEASE) is newer than Fedora $msfr. You may encounter issues."
    else
        util::log "Your Fedora version ($FEDORA_RELEASE) matches the minimum supported version ($msfr)."
    fi
    unset msfr
}

check::terminal() {
    [[ -t 0 && -t 1 && -t 2 ]] || util::panic 'Please run this script in a terminal!'
}

# Install packages with dnf
install::packages() {
    local package_manager="${1-}"
    shift 1

    local -a packages=("$@")
    local joined_packages
    joined_packages=$(util::join "${packages[@]}")

    util::log "Installing packages" "$joined_packages"
    case "$package_manager" in
    --dnf)
        util::do --root dnf install --allowerasing "${packages[@]}"
        ;;
    --pacman)
        util::do --root pacman -S --needed "${packages[@]}"
        ;;
    --flatpak)
        util::do flatpak install flathub "${packages[@]}"
        ;;
    *)
        util::log --error "Unsupported package manager: '$package_manager'"
        ;;
    esac
}

install::update() {
    util::log "Updating system"
    case "$DISTRO" in
    fedora)
        util::do --root dnf upgrade
        ;;
    arch)
        util::do --root pacman -Syu
        ;;
    esac
}

install::rpmfusion() {
    check::fedora_release

    # local -a rpmfusion_packages=(rpmfusion-{,non}free-release)
    local -a rpmfusion_packages
    local -a rpmfusion_urls

    local license_type
    for license_type in free nonfree; do
        rpmfusion_urls+=("https://mirrors.rpmfusion.org/$license_type/fedora/rpmfusion-$license_type-release-$FEDORA_RELEASE.noarch.rpm")
        rpmfusion_packages+=("rpmfusion-$license_type-release")
    done

    if [[ "${1-}" == '--tainted' ]] && util::prompt "Are you sure you want to install tainted rpmfusion?" 'https://rpmfusion.org/FAQ#Free_Tainted'; then
        rpmfusion_packages+=(rpmfusion-{,non}free-release-tainted)
    fi

    local rpmfusion_packages_joined
    rpmfusion_packages_joined=$(util::join "${rpmfusion_packages[@]}")

    if check::installed "${rpmfusion_packages[@]}"; then
        util::log "RPMfusion repositories are already installed" "$rpmfusion_packages_joined"
        return 0
    fi

    install::packages --dnf "${rpmfusion_urls[@]}"
    install::update

    # Necessary for tainted repos
    util::log "Ensuring packages are installed"
    install::packages --dnf "${rpmfusion_packages[@]}"
}

install::flathub() {
    local pkg_manager='--dnf'
    case "$DISTRO" in
    fedora)
        pkg_manager=--dnf
        ;;
    arch)
        pkg_manager=--pacman
        ;;
    esac

    install::packages "$pkg_manager" "${FLATPAK_PACKAGE_PACKAGES[@]}"
    util::do flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    install::packages --flatpak com.github.tchx84.Flatseal
}

install::rustup() {
    sh <(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)
}

ASUS_RPM_COPR='lukenukem/asus-linux'
ASUS_KERNEL_RPM_COPR='lukenukem/asus-kernel'
declare -a ASUS_SERVICES=(power-profiles-daemon.service supergfxd.service)

declare -A EXTRA_COPRS=(
    ['solopasha/hyprland']='A COPR that includes useful Hyprland and Wayland packages'
)

TERRA_RPM_REPO_URL='https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo'

if [[ $DISTRO == fedora ]]; then
    distro::pkglist() {
        dnf repoquery --installed --qf "%{name}"
    }
    NVIDIA_PACKAGES=(akmod-nvidia xorg-x11-drv-nvidia-{power,cuda})
    NVIDIA_OPTIONAL_PACKAGES=()

    CODEC_PACKAGES=(gstreamer1-plugins-{good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel)
    CODEC_FFMPEG_PACKAGES=(ffmpeg{,-devel})

    FLATPAK_PACKAGE_PACKAGES=(flatpak)

    distro::extra_repos() {
        install::packages --dnf dnf-plugins-core

        if util::prompt "install charm.sh repo? (useful CLI tools)" 'https://charm.sh'; then
            echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | util::do --root --noconfirm tee /etc/yum.repos.d/charm.repo
        fi

        if util::prompt "Install terrapkg repo? (useful packages not in fedora or rpmfusion)"
    }

    distro::asus() {
        local -a packages=(switcheroo-control power-profiles-daemon asusctl-rog-gui asusctl supergfxctl)
        util::do --root dnf copr enable 'lukenukem/asus-linux'

        if util::prompt "Do you want to install asus kernel? (For newer machines)" \
            "This kernel uses the same name as the vanilla kernel. You may or may not get an update!"; then
            util::do --root dnf copr enable 'lukenukem/asus-kernel'
        fi

        install::update
        install::packages --dnf "${packages[@]}"
    }
elif [[ $DISTRO == arch ]]; then
    distro::pkglist() {
        pacman -Q | cut -d ' ' -f 1
    }
    NVIDIA_PACKAGES=(libva-nvidia-driver nvidia-dkms nvidia-settings nvidia-utils opencl-nvidia ffnvcodec-headers libvdpau)
    NVIDIA_OPTIONAL_PACKAGES=(cuda opencv-cuda tensorflow-cuda, cudnn)

    CODEC_PACKAGES=(gstreamer-vaapi libheif gst-plugins-{ugly,base,good,bad})
    CODEC_FFMPEG_PACKAGES=(ffmpeg)

    FLATPAK_PACKAGE_PACKAGES=(flatpak)

    distro::asus() {
        local -a packages=(switcheroo-control power-profiles-daemon rog-control-center asusctl supergfxctl)

        local key='8F654886F17D497FEFE3DB448B15A6B0E9A3FA35'
        local cmd
        for cmd in --recv-keys --finger --lsign-key --finger; do
            util::do --root pacman-key $cmd $key
        done

        local pacbak
        pacbak="/etc/pacman.conf_$(util::timestamp).bak"

        util::log "Backing up pacman.conf to $pacbak"
        util::do --root cp /etc/pacman.conf "$pacbak"
        printf '%s\n' '[g14]' 'Server = https://arch.asus-linux.org' | util::do --root --noconfirm tee -a /etc/pacman.conf
        install::update
        install::packages --pacman "${packages[@]}"
    }
fi

# declare -A GRUB_TUNING_ADD_CMDLINE=(
#     [nowatchdog]='Disable watchdog (increases performance)'
#     ['nvme_load=yes']='Load NVME modules early (decreases boot time)'
#     ['modprobe.blacklist=iTCO_wdt']='Disable Intel watchdog (increases performance)'
# )
# declare -A GRUB_TUNING_REMOVE_CMDLINE=(
#     [rhgb]='Shows an image instead of kernel messages (increases boot time)'
#     [quiet]='Suppresses most messages (decreases boot time slightly, but makes debugging harder)'
# )

install::nvidia() {
    local -a packages=("${NVIDIA_PACKAGES[@]}")
    local packages_joined
    packages_joined="$(util::join "${packages[@]}")"

    if ((${#NVIDIA_OPTIONAL_PACKAGES[@]})); then
        local opt_packs_joined
        opt_packs_joined="$(util::join "${NVIDIA_OPTIONAL_PACKAGES[@]}")"
        if util::prompt "Do you want to install optional packages?" "$opt_packs_joined"; then
            packages+=("${NVIDIA_OPTIONAL_PACKAGES[@]}")
            packages_joined="$packages_joined $opt_packs_joined"
        fi
    fi

    case "$DISTRO" in
    fedora)
        install::rpmfusion srrtfgnsrhtx
        install::packages --dnf "${packages[@]}"
        ;;
    arch)
        install::packages --pacman "${packages[@]}"
        ;;
    esac

    local -a services=(nvidia-{hibernate,suspend,resume}.service)

    if util::prompt "enable nvidia-powerd.service?" "(finer power management for RTX 30+ series laptops)"; then
        services+=(nvidia-powerd.service)
    fi

    util::do --root systemctl enable "${services[@]}"

    local -a kernel_cmdline=('rd.driver.blacklist=nouveau' 'modprobe.blacklist=nouveau' 'nvidia-drm.modeset=1')

    util::prompt "Due to the nature of bootloaders, the required kernel command line arguments will not be added." \
        "It is up to you to add the following to your bootloader, removing any duplicates:" \
        '' \
        "$(util::join "${kernel_cmdline[@]}")" \
        '' \
        'For GRUB, add them to /etc/default/grub, then run grub-mkconfig (or grub2-mkconfig) -o <grub config file>' \
        'on Arch, the config file is somewhere around /boot/grub/grub2.cfg. On Fedora, this is /etc/grub2.cfg.' || :
}

declare -A SYSCTL_TUNING_ADD=(
    ['vm.max_map_count=16777216']='Increases the maximum number of pages that can be mapped at once (fixes some games)'
    ['kernel.split_lock_mitigate=0']='Disables logging of split locks (fixes Far Cry 6, The Division, and possibly more)'
)

install::sysctl() {
    local key
    for key in "${!SYSCTL_TUNING_ADD[@]}"; do
        if util::prompt "$key" "${SYSCTL_TUNING_ADD[$key]}"; then
            echo "$key" | util::do --root tee -a /etc/sysctl.d/99-vlk-install.conf
        fi
    done

}

# check::fedora_release
check::terminal

FEDORA_ACTIONS="
1. Install RPMfusion repositories
2. Install Flathub and essential flatpak apps
"

HEADER="$BOLD===Fedora Post-installation Script===$RESET
by vlk


$BOLD== Available actions ==$RESET
"

while true; do
    echo "$HEADER"
    break
done

util::log "Have a nice day!~"
