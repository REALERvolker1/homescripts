#!/usr/bin/bash

set -euo pipefail

echo "Hey! Don't execute this script! You have to read it!"
exit 69

# see useless shit
# printf '%s\n' ~dots/**/*{(N.L0),(N/^F),(N-@)}

if [ "$(ls -l "$(command -v dnf)" | grep -oP ' -> \K.*$')" = 'dnf-3' ]; then
    echo 'dnf-3 found'
    echo -e '\e[1mYou will have to babysit this installer btw\e[0m'
else
    echo "Error, you must have Fedora/RHEL 'dnf3' installed!"
    exit 1
fi

_initialize () {

    sudo dnf update --refresh

    sudo dnf copr enable lukenukem/asus-kernel # asus kernel for 2023 asus laptops
    sudo dnf copr enable lukenukem/asus-linux
    sudo dnf copr enable solopasha/hyprland

    sudo dnf install \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

    sudo dnf update
    sudo dnf install kernel-devel neovim
    sudo dnf install gstreamer1-plugins-{good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
    sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power

    rpm -q neovim &>/dev/null && sudo ln -s "/usr/bin/nvim" '/usr/local/bin/vim'

    sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service

    sudo dnf install asusctl supergfxctl asusctl-rog-gui power-profiles-daemon

    sudo systemctl enable supergfxd.service
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    cmdline="$(grep -oP '^GRUB_CMDLINE_LINUX="\K[^"]*' /etc/default/grub)"

    printf '%s\n' "You will need to change your GRUB_CMDLINE_LINUX to something like" \
        'GRUB_CMDLINE_LINUX="rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1 rhgb quiet"' \
        "Yours is currently:" \
        "$cmdline" \
        '' \
        'Once you do that, reboot!'
    return

}

_pkginst () {
    if dnf copr list | grep -q 'solopasha/hyprland'; then
        #sudo dnf install hyprland hyprpaper hyprpicker hyprshot hyprprop grimblast waybar-git xdg-desktop-portal-hyprland swaylock swayidle
	true
    fi
    sudo dnf group install "C Development Tools and Libraries"
    git clone --depth 1 https://github.com/wbthomason/packer.nvim\
     ~/.local/share/nvim/site/pack/packer/start/packer.nvim
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    sudo dnf install --allowerasing ffmpeg ffmpeg-devel

    sudo dnf install xinput xprop xev wev light gammastep inotify-tools lm_sensors lm_sensors-devel acpi acpica-tools acpitool clipman turbojpeg GraphicsMagick-c++ kvantum qt5ct qt6ct qt5-qtwayland qt6-qtwayland foot libadwaita-devel btop fish ranger xeyes xlsclients git-delta difftastic duf fastfetch chafa cava ranger tmux nodejs-npm typescript shellcheck shfmt git-extras pip gparted slop maim grim slurp pdf2svg sysstat python3-csvkit perl-Image-ExifTool odt2txt mpv vlc evtest hsetroot xsetroot mpv-mpris mangohud d-feet ripgrep socat gnome-keyring gnome-keyring-pam gucharmap gnome-font-viewer gnome-characters piper qpwgraph dconf-editor baobab mediawriter adwaita-qt6 ristretto gh docker distrobox blueman gamemode cmatrix cbonsai hidapi-devel bindfs awf-gtk2 awf-gtk3 awf-gtk4 gimp inkscape trash-cli golang fortune-mod adw-gtk3-theme rofi-wayland picom i3 kitty alacritty gnome-calculator flatpak xfce-polkit fzf git neovim zsh dash lolcat figlet cowsay bat lsd dbus-x11

}

noexec () {
    # stuff I have to run in the terminal at some point idk
    sudo grub2-mkconfig -o /etc/grub2.cfg
    npm config set cache /home/vlk/.local/state/npm
    npm --global cache verify
    npm i -g pnpm
    pnpm setup
    git clone https://github.com/iczero/faf-linux
}

### Function extract for common file formats ###
# Credit: Derek "DistroTube" Taylor
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
function extract {
 if [ -z "$1" ]; then
  # display usage if no parameters given
  echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
  echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
  for n in "$@"
  do
    if [ -f "$n" ] ; then
      case "${n%,}" in
        *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                     tar xvf "$n"       ;;
        *.lzma)      unlzma ./"$n"      ;;
        *.bz2)       bunzip2 ./"$n"     ;;
        *.cbr|*.rar)       unrar x -ad ./"$n" ;;
        *.gz)        gunzip ./"$n"      ;;
        *.cbz|*.epub|*.zip)       unzip ./"$n"       ;;
        *.z)         uncompress ./"$n"  ;;
        *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                     7z x ./"$n"        ;;
        *.xz)        unxz ./"$n"        ;;
        *.exe)       cabextract ./"$n"  ;;
        *.cpio)      cpio -id < ./"$n"  ;;
        *.cba|*.ace)      unace x ./"$n"      ;;
        *)
                     echo "extract: '$n' - unknown archive method"
                     return 1
                     ;;
      esac
    else
      echo "'$n' - file does not exist"
      return 1
    fi
  done
fi
}
IFS=$SAVEIFS

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
