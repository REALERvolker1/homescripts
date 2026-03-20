#!/usr/bin/env bash
# Yeah IK scraping is annoying asf but these companies get what they deserve

IFS=$'\t\n'
set -ueo pipefail

declare -ir MAX_PARALLEL_DOWNLOADS="${MAX_PARALLEL_DOWNLOADS:-5}"

panic() {
    printf '%s\n' "$@" >&2
    exit 1
}

help_panic() {
    panic "USAGE: $0 [--outputdir=/path/to/output | \$OUTPUT_DIR] <url>"
}

# OUTPUT_DIR="${OUTPUT_DIR:-}"
OUTPUT_DIR="$PWD"
TXT_URL=''

for i in "$@"; do
    case "${i:-}" in
    --outputdir=*)
        OUTPUT_DIR="${i#*=}"
        ;;
    -*) help_panic ;;
    *)
        if [[ -z "$TXT_URL" ]]; then
            TXT_URL="$i"
        else
            help_panic
        fi
        ;;
    esac
done

URL_NORMALIZER_OUTPUT=''

# Example of caller being intentionally annoying:
# $1: https://my-cool_sub%20domain.blogwhore.co.uk///////ai%20slop%20generator///index.php/
# $prefix: https
# $swp: my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/index.php
#
# SIDE EFFECTS:
#
# $URL_NORMALIZER_OUTPUT: https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/index.php
url_normalizer() {
    # decls on top so errexit works
    local swp
    local prefix

    swp="${1:?Error, please provide a URL}"
    # keep http or https or ftp intact
    prefix="${swp%%://*}"

    if [[ -z "$prefix" || "$prefix" == */* ]]; then
        panic 'Malformed URL prefix detected' \
            "\`$1\`" \
            "Prefix: \`$prefix\`"
    fi

    swp="${swp#"$prefix://"}"

    # TODO: This ain't pretty but it's probably better than a pure-bash while loop
    swp="$(tr -s '/' <<<"$swp")"

    swp="${swp%/}"

    if [[ "$swp" == /* ]]; then
        # ...odd, leading slashes are not part of the spec
        if [[ "$prefix" == file ]]; then
            # file:///etc/passwd is different, becuase absolute paths start with '/' on normal computers
            # but it is unlikely anyone would pass it in
            panic 'Local file URL passed in, was that your intention?' \
                "\`$1\`" \
                'kinda sus bro ngl'
        else
            panic 'input URL domain name starts with a slash' \
                "\`$1\`" \
                'massive parser bug, this should never be reached'
        fi
    fi

    # Don't make callers run this in a subshell
    URL_NORMALIZER_OUTPUT="$prefix://$swp"
    # printf '`%s` => `%s`\n' "$1" "$URL_NORMALIZER_OUTPUT" >&2
}

url_normalizer "${TXT_URL:?Error, you must provide the URL of an llms.txt to download}"
TXT_URL="$URL_NORMALIZER_OUTPUT"

if [[ "${TXT_URL:-}" != */llms.txt ]]; then
    panic 'Error, you must provide the URL of an llms.txt to download' \
        'Even if it exists in the same API directory as your input, you should still be pretty sure it is in there.'
fi

URL="${TXT_URL%/llms.txt}"

echo "TXT_URL='$TXT_URL'"
echo "URL='$URL'"

# URL = https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/docs
# TXT_URL = https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/docs/llms.txt
#
# Any files after that path should be truncated to the "$OUTPUT_DIR" as its basedir.
# https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/docs/modules/img/ai_slop_images.md
# gets converted to
# "$OUTPUT_DIR/modules/img/ai_slop_images.md"

TXTF="$OUTPUT_DIR/llms.txt"

if [[ ! -f "$TXTF" ]]; then
    echo "Downloading '$TXT_URL' to '$TXTF'"
    curl --fail --location --output "$TXTF" "$TXT_URL"
fi

declare -a mf_urls=()
mapfile -t mf_urls <<<"$(grep -oP '[^\(]+\]\(\K[^\)]+' "$TXTF")"

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

output=''
declare -i i=0

declare -a outputs=()
declare -a urls=()

for url in "${mf_urls[@]}"; do
    # url: https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/docs/modules///img//ai_slop_images.md/
    url_normalizer "$url"
    url="$URL_NORMALIZER_OUTPUT"

    if [[ "$url" != */* ]]; then
        # This was confusing the script when they would have a description of the content
        continue
    fi

    if [[ "$url" != *.md ]]; then
        url="$url/index.md"
    fi

    urls[i]="$url"
    # url: https://my-cool_sub%20domain.blogwhore.co.uk/ai%20slop%20generator/docs/modules/img/ai_slop_images.md
    output="${URL_NORMALIZER_OUTPUT#"$URL"}"
    # output: /modules/img/ai_slop_images.md
    if [[ "$output" != /* ]]; then
        # nah that's alright, the URL will probably just redirect to index.whatever
        # also give it a slash for slavish consistency
        output='/index'
    fi

    output="$OUTPUT_DIR${output}"
    # output: $OUTPUT_DIR/modules/img/ai_slop_images.md

    # Ensure parent dir exists
    # mkdir -p $OUTPUT_DIR/modules/img
    mkdir -p "${output%/*}"
    outputs[i]="$output"
    i=$((i + 1))
done

declare -i num_urls=${#urls[@]}

if [[ $num_urls != ${#outputs[@]} ]]; then
    panic 'Invariant broken' \
        "    Number of URLs:    ${#urls[@]}" \
        "    Number of outputs: ${#outputs[@]}"
fi

declare -i num_loops=$((num_urls / MAX_PARALLEL_DOWNLOADS))
declare -i stragglers=$((num_urls % MAX_PARALLEL_DOWNLOADS))

MYPID="$$"

if [[ -f "$OUTPUT_DIR/failed.log" ]]; then
    rm "$OUTPUT_DIR/failed.log"
fi

parallel_downloads() {
    local -i i
    local -i max
    i=${1:?Nothing to download}
    max=${2:?Nothing to download}

    # convert from the total amount to the ending index
    max=$((max + i))

    # ge comparison because bash arrays start at 0
    if ((max >= num_urls)); then
        panic 'Internal script error, index OOB' \
            "    max: $1" \
            "    i: $i" \
            "    max + i: $max"
    fi

    local -i num_downloads=0
    for ((i = 0; i != max; ++i)); do
        if [[ ! -f "${outputs[i]}" ]]; then
            num_downloads=$((num_downloads + 1))
            # Subshells won't errexit us, unfortunately
            (
                if ! curl --silent --fail --location --output "${outputs[i]}" "${urls[i]}"; then
                    printf 'Download failed: %s\n' "${urls[i]}"
                    printf '%s\t%s\n' \
                        "${urls[i]}" "${outputs[i]}" >>"$OUTPUT_DIR/failed.log"
                fi
            ) &
        fi
    done

    # try not to get ratelimited
    if ((num_downloads != 0)); then
        sleep $num_downloads
        # sleep 5
    fi

    wait
}

i=0

parallel_downloads $i $stragglers

for ((i = stragglers; i < num_loops; ++i)); do
    parallel_downloads $i $MAX_PARALLEL_DOWNLOADS
done
