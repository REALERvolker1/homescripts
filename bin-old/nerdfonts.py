#!/usr/bin/env python3
# A script by vlk to provide a nerd font picker

# It uses a cachefile to store data, because http requests are slow asf
# I'm kinda shit at python but here goes nothing
# at least I have pyright lol, not all hope is lost

from typing import Any, Final, Tuple
from os import environ, listdir, path, mkdir
import json
import subprocess
from shutil import rmtree
import requests

# The URL for nerd font definitions. Change if the API changes.
NERD_FONT_URL: Final = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"

# The representation of an icon
# TODO: I don't think I need this
class Icon:
    def __init__(self, prefix: str, name: str, char: str):
        self.prefix = prefix
        self.name = name
        self.icon = char

class RofiEntry:
    def __init__(self, text: str, icon: str):
        self.text = text
        self.icon = icon

def rofize(entries: list[RofiEntry], msgbox: str | None = None) -> str | None:
    command = ["rofi", "-dmenu"]
    if msgbox != None:
        command.append("-mesg")
        command.append(msgbox)

    subprocess.Popen(command)
    return None

# Get the cache path
def get_cache_path() -> str:
    cache_home = environ.get("XDG_CACHE_HOME")
    if cache_home == None:
        # home = environ.get("HOME")
        home = path.expanduser("~")
        if home == None:
            print("Error, environment variable $HOME is not defined! Your OS environment is very messed up!")
            exit(1)
        else:
            cache_home = path.join(home, ".cache")

    # make XDG_CACHE_HOME if it does not exist, because you needed that anyways
    if not path.isdir(cache_home):
        mkdir(cache_home)

    # multifile for less ram usage loading individual icon families
    mycache_home = path.join(cache_home, "nerdfonts")
    if not path.isdir(mycache_home):
        mkdir(mycache_home)

    return path.join(mycache_home)

# Download the nerd fonts from the URL, storing them in their cachefiles
def get_from_url(cache_path: str) -> Any:

    rmtree(cache_path)
    mkdir(cache_path)
    response = requests.get(NERD_FONT_URL)
    # quick sanity check, make it skip writing and "fail fast" if it is all invalid.
    data = json.loads(response.text)

    icon_families: dict[str, list[dict[str, str]]] = dict()
    for key in data.keys():
        icon = ""
        try:
            # There is a METADATA field I don't need, and there might be random other stuff popping in from time to time.
            icon = data[key]['char']
        except:
            print("Skipping icon for key", key)
            continue
        else:
            # https://www.w3schools.com/python/python_strings_methods.asp
            sme: Tuple[str, str, str] = key.partition("-")
            prefix = sme[0]
            name = sme[2]

            # Hardcoded list of the font families
            # https://github.com/ryanoasis/nerd-fonts/raw/master/images/sankey-glyphs-combined-diagram.svg
            # Family name MUST be file-safe. No slashes!
            # https://docs.python.org/3/tutorial/controlflow.html#tut-match
            match prefix:
                case "pl" | "ple":
                    family_name = "Powerline"
                case "fa" | "fae":
                    family_name = "Font Awesome"
                case "dev":
                    family_name = "Devicons"
                case "weather":
                    family_name = "Weather"
                case "seti" | "custom":
                    family_name = "Seti UI + Custom"
                case "oct":
                    family_name = "Octicons"
                case "linux" | "iec":
                    family_name = "Font Logos"
                case "pom" | "indent" | "indentation":
                    family_name = "Pomicons + Indent"
                case "md":
                    family_name = "Material Design"
                case "cod":
                    family_name = "Codicons"
                case _:
                    family_name = "Other"

            if family_name not in icon_families:
                icon_families[family_name] = []

            icon_families[family_name].append({
                "prefix": prefix,
                "name": name,
                "icon": icon,
            })

    # put the icons into their respective files
    for k in icon_families.keys():
        my_file = path.join(cache_path, f"{k}.json")
        fh = open(my_file, "w")
        json.dump(icon_families[k], fh)
        fh.close()

    print("successfully wrote to cache")

# Read the nerd font stuff from the cachefile, if it exists
def get_selected_family(cache_path: str) -> list[str] | None:
    families = listdir(cache_path)
    if len(families) == 0:
        print("Could not read from cache. Fetching from specified URL", NERD_FONT_URL)
        # This will just panic if it can't get it lol. saves me some useless error handling
        get_from_url(cache_path)
        families = listdir(cache_path)
        if len(families) == 0:
            print("Error, could not find any icon families, even after pulling from github! This script might be broken.")
            exit(2)
    else:
        print("Loaded data from cache:", cache_path)

    family_list = ["ALL"]
    for f in family_list:
        if f.endswith(".json"):
            family_list.append(f.removesuffix(".json"))
        else:
            print(f"Invalid icon family file detected:", f)
            print("For your safety, this script will now exit.")
            exit(3)

    print("\n".join(family_list))

def main():
    cache = get_cache_path()

    selected_family = get_selected_family(cache)

# Apparently this is required in python
if __name__ == "__main__":
    main()
