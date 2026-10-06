#!/bin/sh
set -eu

id="${GOOGLE_WEB_CLIENT_ID:-}"
baked_id=""
if [ -f /usr/share/nginx/html/.vendza-google-client-id ]; then
  baked_id=$(cat /usr/share/nginx/html/.vendza-google-client-id)
fi
case "$id" in
  838466400797*)
    case "$baked_id" in
      838466400797*|"")
        echo "ERROR: GOOGLE_WEB_CLIENT_ID uses the legacy Google Web client prefix 838466400797" >&2
        exit 1
        ;;
      *)
        echo "WARNING: replacing legacy runtime Google Web client with the build-validated client" >&2
        id="$baked_id"
        ;;
    esac
    ;;
esac
escaped=$(printf '%s' "$id" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf 'window.vendzaGoogleWebClientId="%s";\n' "$escaped" \
  > /usr/share/nginx/html/vendza-config.js
