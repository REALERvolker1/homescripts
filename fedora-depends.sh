#!/usr/bin/bash

set -euo pipefail

if [ "$(ls -l "$(command -v dnf)" | grep -oP ' -> \K.*$')" = 'dnf-3' ]; then
    echo 'dnf-3 found'
    echo -e '\e[1mYou will have to babysit this installer btw\e[0m'
else
    echo "Error, you must have Fedora/RHEL 'dnf3' installed!"
    exit 1
fi

_initialize () {

    sudo dnf update --refresh

    sudo dnf copr enable lukenukem/asus-kernel
    sudo dnf copr enable lukenukem/asus-linux
    sudo dnf copr enable solopasha/hyprland

    sudo dnf install \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

    sudo dnf update
    sudo dnf install kernel-devel neovim
    sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda

    rpm -q neovim &>/dev/null && sudo ln -s "/usr/bin/nvim" '/usr/local/bin/vim'

    sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service

    sudo dnf install asusctl supergfxctl asusctl-rog-gui power-profiles-daemon

    sudo systemctl enable supergfxd.service

    cmdline="$(grep -oP '^GRUB_CMDLINE_LINUX="\K[^"]*' /etc/default/grub)"

    printf '%s\n' "You will need to change your GRUB_CMDLINE_LINUX to something like" \
        'GRUB_CMDLINE_LINUX="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 rhgb quiet"' \
        "Yours is currently:" \
        "$cmdline" \
        '' \
        'Once you do that, reboot!'

}

_pkginst () {
    if dnf copr list | grep -q 'solopasha/hyprland'; then
        sudo dnf install hyprland hyprpaper hyprpicker hyprshot hyprprop grimblast waybar-git xdg-desktop-portal-hyprland swaylock swayidle
    fi

    sudo dnf install --allowerasing ffmpeg ffmpeg-devel

    sudo dnf install xinput xprop xev wev light gammastep inotify-tools lm_sensors lm_sensors-devel acpi acpica-tools acpitool clipman turbojpeg GraphicsMagick-c++ kvantum qt5ct qt6ct qt5-qtwayland qt6-qtwayland foot libadwaita-devel btop fish ranger xeyes xlsclients git-delta difftastic duf fastfetch chafa cava ranger tmux nodejs-npm typescript shellcheck shfmt git-extras pip gparted slop maim grim slurp pdf2svg sysstat python3-csvkit perl-Image-ExifTool odt2txt mpv vlc evtest hsetroot xsetroot mpv-mpris mangohud d-feet ripgrep socat gnome-keyring gnome-keyring-pam gucharmap gnome-font-viewer gnome-characters piper qpwgraph dconf-editor baobab mediawriter adwaita-qt6 ristretto gh docker distrobox blueman gamemode cmatrix cbonsai hidapi-devel bindfs awf-gtk2 awf-gtk3 awf-gtk4 gimp inkscape trash-cli golang fortune-mod adw-gtk3-theme rofi-wayland picom i3 kitty alacritty gnome-calculator flatpak xfce-polkit fzf git neovim zsh dash lolcat figlet cowsay bat lsd

}

case "$1" in
    '--init')
        _initialize
        ;;
    '--pkg')
        _pkginst
        ;;
    *)
        printf '%s\t%s\n' \
            '--init' 'install initial packages (rpmfusion, coprs, asus shit)' \
            '--pkg' 'install all the rest of the packages'
        ;;
esac
