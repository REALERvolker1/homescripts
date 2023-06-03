#!/usr/bin/env python3
# script by vlk

import os
import json
import subprocess

TITLE = "Nerd Fonts Selector v2 by vlk"

# config
favorites = ["md", "ple"]
try:
    pango_color = os.environ['ROFI_NORMAL']
except:
    pango_color = "#FFFFFF"

pango_font = "Symbols Nerd Font"


def iconize(icon):
    return f"\0icon\x1f<span color='{pango_color}' font='{pango_font}'>{icon}</span>"


def rofize(data_array, previous_action):
    rofi = subprocess.Popen(
        ['rofi', '-dmenu', '-mesg', previous_action], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    rofi.stdin.write(bytes('\n'.join(data_array), 'utf-8'))
    # output = rofi.communicate()[0]
    # return output.decode('utf-8').strip()
    output = rofi.communicate()[0].decode('utf-8').strip()
    if not output:
        print("Error: Could not parse output from rofize")
        exit(1)
    else:
        return output


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


def main():
    icon_file = open(
        f"{os.environ['XDG_CACHE_HOME']}/nerd-font-icons.json", 'r')
    icon_file_contents = icon_file.read()
    icon_file.close()

    icon_object = json.loads(icon_file_contents)

    icon_families = []

    for i in icon_object:
        family = f"{i['family']} icons{iconize(i['icons'][3]['icon'])}"
        if favorites.__contains__(i['family']):
            icon_families.insert(0, family)
        else:
            icon_families.append(family)

    icon_families.insert(len(favorites), f"Show All{iconize('')}")

    selected_family_name = rofize(
        icon_families, TITLE).removesuffix(" icons")

    selected_family_icon_strings = []

    if selected_family_name == "Show All":
        selected_family_name = "ALL"
        selected_family = []
        for i in icon_object:
            for j in i["icons"]:
                selected_family.append(j)
    else:
        for i in icon_object:
            if i['family'] == selected_family_name:
                selected_family = i["icons"]

        if not selected_family:
            print("Error: Selected family not found")
            exit(1)

    for i in selected_family:
        if 'name' in i and 'icon' in i:
            selected_family_icon_strings.append(
                f"{i['name']} {i['icon']}{iconize(i['icon'])}")

    selected_icon_raw = rofize(
        selected_family_icon_strings, f"Currently viewing {selected_family_name} icons")
    selected_icon = selected_icon_raw[-1]
    selected_icon_name = selected_icon_raw.split()[0]

    selected_action = rofize(
        [f"Insert {selected_icon}\0icon\x1fkey_bindings", #{iconize('󰥻')}
         f"Copy {selected_icon}\0icon\x1fedit-copy-symbolic"],
        f"Selected icon: {selected_icon_name} {selected_icon}"
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


if __name__ == "__main__":
    main()

"""


families = []
global_icons = []


class IconFamily:
    def __init__(self, family):
        self.family = family

    icons = []


class Icon:
    def __init__(self, family, name, codepoint):
        self.family = family
        self.name = f"{family}_{name}"
        self.codepoint = codepoint


def string_out(icon):  # Icon => string
    return f"{icon.name}\\0icon\\x1f<span>{icon.codepoint}</span>"


for family_name_codepoint in icon_file_contents.splitlines():
    icon_tuple = family_name_codepoint.split()

    global_icons.append(
        Icon(icon_tuple[0], icon_tuple[1], icon_tuple[2])
    )

for icon in icons:
    print(string_out(icon))
"""
