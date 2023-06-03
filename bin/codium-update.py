#!/usr/bin/env python3

import requests
import shutil
import os
import sys
import json

INSTALL_DIR = "/home/vlk/.local/opt/vscodium"
PREF_VERSION = "VSCodium-linux-x64"

VERSION_LOCKFILE  = f"{INSTALL_DIR}/data/version.lock"
UNPACK_FILE = f"{INSTALL_DIR}/vscodium.tar.gz"

REPOSITORY_URL = "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
REPOSITORY_URL_PARAMS = dict(
        Accept="application/vnd.github+json",
        #X-GitHub-Api-Version="2022-11-28",
)

#REPOSITORY_ARTIFACT_URL = "https://api.github.com/repos/VSCodium/vscodium/releases/assets"
#REPOSITORY_ARTIFACT_URL_PARAMS = dict(
#        Accept="application/octet-stream"
#)

def pprint(json_str):
    formatted = json.dumps(json_str, indent=2)
    print(formatted)

lockFile = open(VERSION_LOCKFILE, "r")
lockVersion = lockFile.read()
lockFile.close()

print(f"Updating vscodium. Current version: {lockVersion}")

repo_request = requests.get(url=REPOSITORY_URL, params=REPOSITORY_URL_PARAMS)
repoContent = repo_request.json()
repoDate = repoContent["published_at"]

if "--ignore" not in sys.argv:
    if repoDate == lockVersion:
        print(f"Already up to date! {repoContent['published_at']}")
        exit()
else:
    print("Passed flag `--ignore`. Ignoring version lock")

lockWrite = open(VERSION_LOCKFILE, "w")
lockWrite.write(repoDate)
lockWrite.close()

repoAssets = repoContent["assets"]

for asset in repoAssets:
    name = asset["name"]
    if name.startswith(PREF_VERSION) & name.endswith("tar.gz"):
        #chosen_id = asset["id"]
        chosen_name = name
        chosen_url = asset["browser_download_url"]
        chosen_size = round((asset["size"] / 1024 / 1024), 2)

try:
    print(f"Downloading {chosen_name} ({chosen_size} MiB) [{repoDate}]...")
except:
    print("Error: Could not get the chosen package.")
    exit(1)

#print(f"{REPOSITORY_ARTIFACT_URL}{chosen_id}")
#artifact_request = requests.get(f"{REPOSITORY_ARTIFACT_URL}/{chosen_id}", params=REPOSITORY_ARTIFACT_URL_PARAMS)
artifact_request = requests.get(chosen_url)

archive_file = open(UNPACK_FILE, "wb")
archive_file.write(artifact_request.content)
archive_file.close()

print("Unpacking and replacing files...")

shutil.unpack_archive(UNPACK_FILE, INSTALL_DIR)

print("Done unpacking. Cleaning up...")

if os.path.isfile(UNPACK_FILE):
        os.remove(UNPACK_FILE)

print(f"{chosen_name} installed successfully.")
