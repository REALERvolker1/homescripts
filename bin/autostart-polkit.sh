#!/usr/bin/dash

for i in \
    '/usr/libexec/xfce-polkit' \
    '/usr/lib/xfce-polkit/xfce-polkit' \
    '/usr/libexec/polkit-mate-authentication-agent-1' \
    '/usr/lib/mate-polkit/polkit-mate-authentication-agent-1' \
    '/usr/libexec/polkit-gnome-authentication-agent-1' \
    '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' \
    '/usr/libexec/lxqt-policykit-agent' \
    'lxpolkit'; do
    [ -x "$i" ] && exec "$i"
done

echo "Error, could not find a polkit agent!"
