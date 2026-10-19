# Included at server level and in locations that declare Cache-Control.
# Nginx does not inherit parent add_header directives when a location has its own.
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Cross-Origin-Opener-Policy "same-origin-allow-popups" always;
add_header Permissions-Policy "camera=(self), microphone=(), geolocation=()" always;
add_header Content-Security-Policy "default-src 'self' https: data: blob:; base-uri 'self'; object-src 'none'; frame-ancestors 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https: blob:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: blob: https:; font-src 'self' data: https:; connect-src 'self' https: wss:; worker-src 'self' blob:; frame-src 'self' https:; form-action 'self' https:; upgrade-insecure-requests" always;
