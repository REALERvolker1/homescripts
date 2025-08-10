#!/usr/bin/env bash
IFS=$'\n\t'
set -euo pipefail

hash curl || exit 3

ME="${0##*/}"
print_help() {
    if [[ -n "${1:-}" ]]; then
        echo "$@"
    fi

    echo "USAGE: $ME --ext <EXTENSION ID> --version VERSION --platform PLATFORM --output /path/to/output.vsix

Sort of like the built-in vscode command \`ext install <EXTENSION ID>\`.

Default version behavior is to query the latest, but this may not be correct for your target platform.
For best results, check the marketplace website.

Currently known target platforms:
  Alpine Linux ARM64  alpine-arm64
  Linux ARM32         linux-armhf
  Linux ARM64         linux-arm64
  (default) Linux x64 linux-x64
  Windows ARM         win32-arm64
  Windows x64         win32-x64
  macOS Apple Silicon darwin-arm64
  macOS Intel         darwin-x64

Set it to NULL to disable target platform (for universal extensions)"
    exit 1
}

extension="${1:---help}"
version=''
platform=''
output=''
declare -i current_arg=0

for i in "$@"; do
    if ((current_arg == 0)); then
        case "$i" in
        '--ext') current_arg=1 ;;
        '--version') current_arg=2 ;;
        '--platform') current_arg=3 ;;
        '--output') current_arg=4 ;;
        *)
            print_help "Invalid argument: $i"
            ;;
        esac
        continue
    fi

    case "$current_arg" in
    1) extension="$i" ;;
    2) version="$i" ;;
    3) platform="$i" ;;
    4) output="$i" ;;
    *)
        echo "Internal argument parser error!"
        exit 13
        ;;
    esac

    current_arg=0
done

curlcmd=(-f -L)

if [[ -z ${extension:-} ]]; then
    print_help "Missing extension ID!"
fi
if [[ -z ${output:-} ]]; then
    curlcmd+=("-O")
else
    curlcmd+=("--output" "$output")
fi

# Hopefully these are sane defaults?
: "${version:=latest}" "${platform:=linux-x64}"

if [[ $platform == NULL ]]; then
    platform=''
else
    platform="?targetPlatform=$platform"
fi

publisher="${extension%%.*}"
ext_id="${extension#*.}"

url_to_get="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${ext_id}/${version}/vspackage${platform}"

echo "$url_to_get"
echo "
Automatic download is broken rn sowwy, you have to go to that link in a browser manually 😭"

# curl "${curlcmd[@]}" "$url_to_get"
