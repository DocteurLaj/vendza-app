#!/bin/sh
set -eu

id="${GOOGLE_WEB_CLIENT_ID:-}"
escaped=$(printf '%s' "$id" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf 'window.vendzaGoogleWebClientId="%s";\n' "$escaped" \
  > /usr/share/nginx/html/vendza-config.js
