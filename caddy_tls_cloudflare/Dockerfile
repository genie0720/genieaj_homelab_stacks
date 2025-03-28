# For prod you'd want to pin the version: e.g., 2.9.1-builder
FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http \
    --with github.com/hslatman/caddy-crowdsec-bouncer/layer4 \
    --with github.com/hslatman/caddy-crowdsec-bouncer/appsec \
    --with github.com/WeidiDeng/caddy-cloudflare-ip
FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy