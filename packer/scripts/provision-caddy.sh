#!/usr/bin/env bash
# Golden-image provisioner: install Caddy, drop the sample page + Caddyfile, and
# enable the service so a deploy from the template serves the page and exposes
# /metrics (dedicated Caddy metrics listener :2019/metrics, admin off →
# job="caddy" scrape) on first boot.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Caddy from the official apt repo (pinned major line; the image is rebuilt to
# bump — reproducible + diffable, the point of the Packer pipeline).
apt-get update -y
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -fsSL 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

install -d /srv
install -m 0644 /tmp/kaddy/index.html /srv/index.html
install -m 0644 /tmp/kaddy/Caddyfile /etc/caddy/Caddyfile

systemctl enable caddy
caddy validate --config /etc/caddy/Caddyfile

# Cleanup so the exported snapshot is lean.
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/kaddy
