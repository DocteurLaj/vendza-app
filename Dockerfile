# syntax=docker/dockerfile:1.7

ARG FLUTTER_VERSION=3.44.2
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION
ARG VENDZA_API_BASE_URL
ARG VENDZA_MEDIA_BASE_URL=""
ARG GOOGLE_WEB_CLIENT_ID=""

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --no-analytics \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN test -n "${VENDZA_API_BASE_URL}" \
    && case "${VENDZA_API_BASE_URL}" in https://*) ;; *) exit 1 ;; esac \
    && flutter build web --release \
      --dart-define=VENDZA_API_BASE_URL="${VENDZA_API_BASE_URL}" \
      --dart-define=VENDZA_MEDIA_BASE_URL="${VENDZA_MEDIA_BASE_URL}" \
      --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID}"

FROM nginxinc/nginx-unprivileged:1.29-alpine AS runtime

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8080/healthz || exit 1
