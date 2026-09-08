# Personal desktop services

Hyprland and i3 still call `~/bin/autostart.sh`. It finalizes UWSM for managed
Wayland sessions, or imports the required environment for unmanaged sessions,
then starts `wayland.target` or `xorg.target`. Both pull in
`user-graphical-session.target` for shared services. The targets list their
services explicitly, so no separate `systemctl enable` step is needed.

Each program has its own service and journal. Long-running programs restart on
failure; setup commands run once per session. Dunst and ydotool use their
installed package units. The already enabled ydotool service keeps its existing
user-login lifetime. Commented-out programs from the old script remain disabled.

UWSM loads toolkit settings from `~/.config/uwsm/env-hyprland` before launching
Hyprland. It supplies the XDG desktop/session identity variables and cleans up
the session environment on logout. Use the UWSM-managed Hyprland login entry.
Environment edits take effect on the next login, not on a Hyprland config reload.

Stopping `graphical-session.target` stops the desktop services. UWSM handles
this on logout; the X11 `xinitrc` also stops it when its desktop exits. Other
unmanaged launchers need the same logout hook. These targets support one
graphical session per user at a time.

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
