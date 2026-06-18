#!/usr/bin/env bash
set -euo pipefail

: "${FUCK_ISPS_URL:=furaffinity.net}" "${FUCK_ISPS_MAX_TIME:=5}"

if [[ -z ${FUCK_AMAZON_CENSORSHIP-} ]]; then
	FUCK_AMAZON_CENSORSHIP='<title>eero - Device Paused</title>'
fi

response=$(curl -s --max-time "$FUCK_ISPS_MAX_TIME" "$FUCK_ISPS_URL" 2>/dev/null)
status=$(curl -s -o /dev/null --max-time "$FUCK_ISPS_MAX_TIME" -w "%{http_code}" "$FUCK_ISPS_URL")

# If HTTP status is NOT 200, definitely offline
if (((status / 100) != 2)); then
	exit 1
fi

# If response CONTAINS your router's error message, blocked
if grep --ignore-case --quiet "$FUCK_AMAZON_CENSORSHIP" <<<"$response"; then
	exit 1
fi

exit 0
