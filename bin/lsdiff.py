#!/usr/bin/python3
# lsdiff.py, by vlk
# https://github.com/REALERvolker1/homescripts
import os
from sys import argv
import subprocess

DIFF_FILE = f"{os.environ['XDG_CACHE_HOME']}/pylsdiff.cache"

# content = subprocess.check_output(f"lsd --ignore-config -A --group-dirs first --color always --icon always '{DIFF_FILE}'")
# f"lsd --ignore-config -A --group-dirs first --color always --icon always '{DIFF_FILE}'"
# [ "lsd", "--ignore-config", "-A", "--group-dirs", "first", "--color", "always", "--icon", "always", DIFF_FILE ]
content = subprocess.run([ "lsd", "--ignore-config", "-A", "--group-dirs", "first", "--color", "always", "--icon", "always", DIFF_FILE ], capture_output=True, shell=True, text=True).stdout
if len(content) == 0:
    exit(1)

print(content)
if not os.path.exists(DIFF_FILE) or argv[1] == "--update":
    print(f"Found config file {DIFF_FILE}")
