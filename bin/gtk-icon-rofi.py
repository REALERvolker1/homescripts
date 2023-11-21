#!/usr/bin/env python3
import subprocess
import os
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

def copy(icon):
    if os.environ.get('WAYLAND_DISPLAY') is not None:
        xclip = subprocess.Popen(
            ['wl-copy', '-n', icon], stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )
    else:
        xclip = subprocess.Popen(
            ['xclip', '-selection', 'clipboard'], stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )
        xclip.stdin.write(bytes(icon, 'utf-8'))
        xclip.stdin.close()

    return xclip.returncode


def insert(icon):
    if os.environ.get('WAYLAND_DISPLAY') is not None:
        xdotool = subprocess.Popen(
            ['wtype', icon], stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )
    else:
        xdotool = subprocess.Popen(
            ['xdotool', 'type', icon], stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )

    return xdotool.returncode

def rofize(icon_array, message):
    rofi = subprocess.Popen(['rofi', '-dmenu', '-mesg'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    rofi.stdin.write(bytes('\n'.join(icon_array), 'utf-8'))
    output = rofi.communicate()[0].decode('utf-8').strip()
    if not output:
        exit(1)
    else:
        return output

def icon_theme_select(icon_theme):
    icon_names = icon_theme.list_icons()
    icons = []
    for icon in icon_names:
        icons.append(f"{icon}\0icon\x1f{icon}")

    selected_icon = rofize(icons, "vlk GTK icon selector v5")
    print(selected_icon)

    selected_action = rofize(
        [f"Insert {selected_icon}\0icon\x1fkey_bindings", f"Copy {selected_icon}\0icon\x1fedit-copy-symbolic"],
        f"Selected icon: {selected_icon}"
    ).split()[0]

    if selected_action == "Insert":
        retval = insert(selected_icon)
    elif selected_action == "Copy":
        retval = copy(selected_icon)
    else:
        print("Error! No action selected!")
        exit(1)

    if retval:
        print(f"There were some errors executing the command: {retval}")
    else:
        print("Have a nice day! ~")


def main():
    icon_theme = Gtk.IconTheme.get_default()
    icon_theme_select(icon_theme)


if __name__ == "__main__":
    main()


