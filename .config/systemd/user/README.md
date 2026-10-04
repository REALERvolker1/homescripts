# Personal desktop services

Hyprland and i3 still call `~/bin/autostart.sh`. It finalizes UWSM for managed
Wayland sessions, or imports the required environment for unmanaged sessions,
then starts `wayland.target` or `xorg.target`. Both pull in
`user-graphical-session.target` for shared services. The targets list their
services explicitly, so no separate `systemctl enable` step is needed.
After starting the target, `autostart.sh` restarts `xdg-desktop-portal.service`.
This refreshes a portal activated during an earlier SSH login, once UWSM or i3
has exported the graphical session environment. The packaged portal unit is
already `PartOf=graphical-session.target`, so it stops with the session.

Each program has its own service and journal. Long-running programs restart on
failure; setup commands run once per session. Dunst and ydotool use their
installed package units. A ydotool drop-in ties its lifetime to the graphical
session; `user-graphical-session.target` starts it. The custom NetworkManager
unit starts the applet for both desktops, and a user autostart override hides
the system-wide XDG entry. Commented-out programs from the old script remain
disabled.

UWSM loads toolkit settings from `~/.config/uwsm/env-hyprland` before launching
Hyprland. It supplies the XDG desktop/session identity variables and cleans up
the session environment on logout. Use the UWSM-managed Hyprland login entry.
Environment edits take effect on the next login, not on a Hyprland config reload.

Stopping `graphical-session.target` stops the desktop services. UWSM handles
this on logout; the X11 `xinitrc` also stops it and clears X11 desktop variables
from the lingering user manager when its desktop exits. Other unmanaged
launchers need the same logout hook. These targets support one graphical
session per user at a time. `hyprpm-reload.service` skips startup when hyprpm
is not installed; plugin loading remains available when it is installed.

After changing unit files:

```sh
systemctl --user daemon-reload
```

Log out and back in for the initial migration. Starting these targets while
the old script's programs are still running can create duplicate processes.

```sh
systemctl --user status quickshell.service
journalctl --user -u quickshell.service -b
systemctl --user restart quickshell.service
systemctl --user list-dependencies wayland.target
```

`autotiling-rs` and `nvidia-settings` are currently absent. Their X11 units use
`ConditionFileIsExecutable` and are skipped until the programs are installed.
The conversion preserves the old `xhost +local:` command and Wayland cleanup
of `~/.xsession-errors` and `~/.Xauthority`.
