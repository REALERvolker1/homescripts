#!/dev/null
# vim:foldmethod=marker:ft=i3config

# x11 stuff
$exec dbus-update-activation-environment --systemd --verbose DISPLAY XAUTHORITY
$exec xrdb -merge "$XRESOURCES"
$exec xlayoutdisplay --quiet

# DE stuff
$exec xfce-polkit.sh
$exec "killall dunst; dunst"
#$exec gnome-keyring-daemon -r
#$exec nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" -l
#$exec ~/.local/lib/hardcoded-keyring-unlocker
$exec xsettingsd


# scripts
$exec volbright.sh --brightness --volume --keyboard
$exec steam-symlink-unfucker.sh

# Power management
$exec xset -dpms
$exec xss-lock -l "vlklock.sh"
$exec pmgmt.sh
$exec "killall xplugd; xplugd"

# Input configs
$exec numlockx
$exec pointer.sh -n
$exec xmodmap -e "clear lock"
$exec xmodmap -e "keycode 66 = Escape NoSymbol Escape"

# Bar icons
$exec xfce4-clipman
$exec nm-applet
# $exec rog-control-center
$exec flameshot

# visuals
$exec picom
$exec flashfocus
$exec "killall gammastep; gammastep -P"
#$exec set-cursor-theme.sh --session

#$exec scratchpad_terminal.sh

# exec_always field
#$execa hsetroot -cover "$(printf '%s\n' $XDG_DATA_HOME/backgrounds/* | shuf | head -n 1)"
$execa vlkbg.sh
$execa kitti3 -s 0.75 1.0 -p RC
