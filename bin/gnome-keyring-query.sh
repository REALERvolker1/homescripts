#!/usr/bin/dash
# script by vlk

is_locked="$(busctl --user get-property 'org.gnome.keyring' '/org/freedesktop/secrets/collection/login' 'org.freedesktop.Secret.Collection' 'Locked')"
case "$is_locked" in
    'b false')
        echo 󰍀
    ;; 'b true')
        echo 󰌾
    ;; *)
        echo 󰌾?
    ;;
esac


# You can't monitor the actual property for changes, you have to update on stdin
# dbus-monitor --session "type='signal',sender='org.gnome.keyring',path='/org/freedesktop/secrets/collection/login',interface='org.freedesktop.Secret.Collection'"

# To make it autostart
# sudoedit /etc/pam.d/login
# auth     optional  pam_gnome_keyring.so
# session  optional  pam_gnome_keyring.so auto_start

