#!/usr/bin/bash
# shellcheck shell=bash
# a script by vlk that installs nvidia drivers and other stuff on Fedora
# TODO: Remove all raw ansi escapes from this script

safe_mode() {
    set -euo pipefail
    IFS=$'\n\t'
}
unsafe_mode() {
    set +euo pipefail
}
safe_mode
# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

for dir in "${XDG_DATA_HOME:=$HOME/.local/share}" "${XDG_CONFIG_HOME:=$HOME/.config}" "${XDG_CACHE_HOME:=$HOME/.cache}"; do
	if [[ ! -d "$dir" ]]; then
		mkdir -p "$dir"
	fi
done


# dependency check
# declare -a faildeps=()
# for i in dnf grep sed tee sudo; do
#     command -v "$i" &>/dev/null || faildeps+=("$i")
# done
# ((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"

# TODO: Error handling is shite, this should not just fail and quit immediately, it should log commands that failed and stuff
_do() {
    local -a stuff=()
    if [[ ${1:?Error, nothing to do!} == '--root' ]]; then
        shift 1
        stuff+=(sudo)
    fi
    stuff=("${stuff[@]}" "$@")
    if ! sudo -vn &>/dev/null; then
        local ans
        printf '%s\n' \
            '[0;1;91mSUDO REQUIRED[0m' \
            'Are you sure you want to do this?'
        echo "${stuff[@]}"

        read -r -p "[y/N] > " ans
        [[ ${ans:-} == y ]] || return 1
    fi

    local oldifs="$IFS"
    local IFS=' '
    local cmd="${stuff[*]}"
    IFS="$oldifs"

    if ((DRY)); then
        echo "[DRY] Skipping command: '$cmd'"
    else
        unsafe_mode
        sh -c "$cmd"
        local -i cmdretval=$?
        safe_mode
        ((cmdretval)) && local errmsg='Error, command returned an error'
        echo "${errmsg:-Successfully ran command}: '$cmd'"
        return $cmdretval
    fi
}

# TODO: Download in parallel
install_rpmfusion() {
    local fedora_release
    fedora_release="$(rpm -E %fedora)"
    local installed
    installed="$(dnf list installed)"
    for i in {free,nonfree}; do
        if [[ $installed == *"rpmfusion-$i-release"* ]]; then
            echo "Skipping, rpmfusion-$i-release is already installed"
        else
            _do --root dnf install "https://mirrors.rpmfusion.org/$i/fedora/rpmfusion-$i-release-$fedora_release.noarch.rpm"
        fi
    done
    if [[ ${1:-} == '--tainted' ]]; then
        for i in rpmfusion-{,non}free-release-tainted; do
            if [[ $installed == *"$i"* ]]; then
                echo "Skipping, $i is already installed"
            else
                _do --root dnf install "$i"
            fi
        done
    fi
    _do --root dnf update --refresh
}

install_flathub() {
    if dnf list | grep -q flatpak; then
	    # This is unnecessary
        echo flatpak already installed
    else
        _do --root dnf install flatpak
    fi
    _do flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

if [[ ${1:-} == '--dry-run' ]]; then
    ROOTDIR="$HOME/$0-dry-deleteme/"
    DRY=1
else
    ROOTDIR="/"
    DRY=0
fi
declare -r ROOTDIR
declare -ir DRY

header="[0;1m===Fedora Driver Installer===[0m

[0;1mWARNING: This program could automate the installation of NONFREE software that is ILLEGAL to distribute in certain European/Asian countries.[0m
For more information, please see https://rpmfusion.org/FAQ#Free_Tainted

Available options:
1. Install nvidia drivers
2. Install ffmpeg (full version) and other codecs
3. Install libdvdcss


[0;1mThese options install Free software from a third-party COPR repository, make sure you trust the developers first.[0m

4. Install Asus-Linux compatibility programs
-- asusctl, supergfxctl, asus-rog-gui, power-profiles-daemon, switcheroo-control
-- Read https://asus-linux.org/wiki/fedora-guide for more information
-- https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux

5. Install Asus-Linux kernel
-- required for newer Asus laptops, especially those that come with a behind-screen display
-- https://copr.fedorainfracloud.org/coprs/lukenukem/asus-kernel

6. Install Hyprland
-- hyprland, xdg-desktop-portal-hyprland
-- https://copr.fedorainfracloud.org/coprs/solopasha/hyprland


[0;1mInstall other useful tools.[0m

7. Install rustup
-- CARGO_HOME will be set to $XDG_DATA_HOME/cargo
-- RUSTUP_HOME will be set to $XDG_DATA_HOME/rustup
-- sh <(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)

8. Install flatpak and flathub

9. Install adw-gtk3
9a. Install gradience along with that for libadwaita customization

q (or CTRL+C). Quit
"

while :; do
    user_selection=''
    # echo ""
    read -r -p "$header> [0;1m" user_selection
    echo -n '[0m'
    case "${user_selection:-}" in
    1)
        install_rpmfusion _
        _do --root dnf install 'kernel-devel'
        _do --root dnf install akmod-nvidia xorg-x11-drv-nvidia-{power,cuda}
        _do --root systemctl enable nvidia-{hibernate,suspend,resume}.service
        read -r -p "Enable nvidia-powerd? (For RTX 30+ series laptops)"$'\n''[y/N] > ' powerd_answer
        [[ ${powerd_answer:-x} == y ]] && _do --root systemctl enable nvidia-powerd.service

        # _do --root sed -Ei 's/^(GRUB_CMDLINE_LINUX=").*/\1rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1/g ; s/^(GRUB_TIMEOUT).*/\1=1/g' /etc/default/grub
	echo "Add the following to your /etc/default/grub under GRUB_CMDLINE_LINUX, remove all duplicate entries

        rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1

Then run the command: 'sudo grub2-mkconfig -o /etc/grub2.cfg'"
        # _do --root grub2-mkconfig -o /etc/grub2.cfg

        # declare -a modules=('rd.driver.blacklist=nouveau' 'modprobe.blacklist=nouveau' 'nvidia-drm.modeset=1')
        # add 'nowatchdog nvme_load=yes' for my laptop

        # echo "[0;1mReboot your system to apply changes[0m"
        ;;
    2)
        install_rpmfusion
        _do --root dnf install gstreamer1-plugins-{good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
        _do --root dnf install --allowerasing ffmpeg ffmpeg-devel
        ;;
    3)
        install_rpmfusion --tainted
        _do --root dnf install libdvdcss vlc
        ;;
    4)
        _do --root dnf copr enable 'lukenukem/asus-linux'
        _do --root dnf update --refresh
        _do --root dnf install switcheroo-control power-profiles-daemon asusctl-rog-gui asusctl supergfxctl
	# TODO: Enable power-profiles-daemon and switcheroo-control services
        _do --root systemctl enable supergfxd.service
        ;;
    5)
        _do --root dnf copr enable 'lukenukem/asus-kernel'
	# The Asus-kernel uses the same package name as the vanilla kernel.
	# TODO: Mention this
        _do --root dnf update --refresh
        echo "You will have to exclude Fedora kernel updates manually. Please see https://asus-linux.org/wiki/fedora-guide/#use-custom-kernel"
        echo "[0;1mReboot your system to apply changes[0m"
        ;;
    6)
	    # TODO: Remove this
        _do --root dnf copr enable 'solopasha/hyprland'
        _do --root dnf update --refresh
        _do --root dnf install hyprland 'xdg-desktop-portal-hyprland'
        printf '%s\n' \
            "If you have any trouble with xdg-desktop-portal-hyprland, run" \
            'systemctl enable xdg-desktop-portal-hyprland.service'
        ;;
    7)
        sh <(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)
        ;;
    8)
        install_flathub
        _do flatpak install flathub com.github.tchx84.Flatseal
        ;;
    9*)
	    # TODO: Mention that this installs flatpak too, maybe provide option to not do that
        install_flathub
        _do --root dnf install adw-gtk3-theme
        _do flatpak install flathub org.gtk.Gtk3theme.adw-gtk3{,-dark}
        if [[ ${user_selection:-} == '9a' ]]; then
            _do flatpak install flathub com.github.GradienceTeam.Gradience
        fi
        ;;
    [qQ])
        exit 0
        ;;
    *)
        echo "Invalid selection: '${user_selection:-}'!"
        ;;
    esac
    echo press ENTER to continue
    read -r
done
