#!/bin/sh
set -eu

id="${GOOGLE_WEB_CLIENT_ID:-}"
case "$id" in
  838466400797*)
    echo "ERROR: GOOGLE_WEB_CLIENT_ID uses the legacy Google Web client prefix 838466400797" >&2
    exit 1
    ;;
esac
escaped=$(printf '%s' "$id" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf 'window.vendzaGoogleWebClientId="%s";\n' "$escaped" \
  > /usr/share/nginx/html/vendza-config.js
