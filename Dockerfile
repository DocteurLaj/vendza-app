# syntax=docker/dockerfile:1.7

ARG FLUTTER_VERSION=3.44.2
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION
ARG VENDZA_API_BASE_URL="https://vendza-vendzaapi-lenoer-604821-72-60-90-32.sslip.io/api/v1"
ARG VENDZA_MEDIA_BASE_URL="https://vendza-vendzaminiostorage-tx8h0h-c106eb-72-60-90-32.sslip.io"
ARG GOOGLE_WEB_CLIENT_ID=""

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}" \
    GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=safe.directory \
    GIT_CONFIG_VALUE_0=/opt/flutter

RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN test -n "${VENDZA_API_BASE_URL}" \
    && case "${VENDZA_API_BASE_URL}" in https://*) ;; *) exit 1 ;; esac \
    && if [ -z "${GOOGLE_WEB_CLIENT_ID}" ]; then \
         echo "WARNING: GOOGLE_WEB_CLIENT_ID build-arg is empty. The Google button will be hidden. Set it as a Docker BUILD ARG in Dokploy (not a runtime Environment variable), then rebuild without cache."; \
       else \
         echo "GOOGLE_WEB_CLIENT_ID build-arg is set."; \
       fi \
    && flutter build web --release \
      --dart-define=VENDZA_API_BASE_URL="${VENDZA_API_BASE_URL}" \
      --dart-define=VENDZA_MEDIA_BASE_URL="${VENDZA_MEDIA_BASE_URL}" \
      --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID}"

FROM nginxinc/nginx-unprivileged:1.29-alpine AS runtime

ENV GOOGLE_WEB_CLIENT_ID=""

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
COPY deploy/docker-entrypoint.d/40-vendza-config.sh /docker-entrypoint.d/40-vendza-config.sh
USER root
RUN chmod +x /docker-entrypoint.d/40-vendza-config.sh \
    && printf 'window.vendzaGoogleWebClientId="";\n' > /usr/share/nginx/html/vendza-config.js \
    && chown -R 101:101 /usr/share/nginx/html /docker-entrypoint.d/40-vendza-config.sh
USER 101

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8081/healthz || exit 1
