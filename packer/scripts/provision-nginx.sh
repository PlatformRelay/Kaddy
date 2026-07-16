#!/usr/bin/env bash
# Golden-image provisioner (nginx mirror): install nginx + nginx-prometheus-exporter,
# drop the sample page + config, enable both services so a deploy serves the page
# and exposes /metrics (exporter republishes /stub_status under job="caddy").
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx curl

install -d /srv
install -m 0644 /tmp/kaddy/index.html /srv/index.html
install -m 0644 /tmp/kaddy/nginx.conf /etc/nginx/nginx.conf

# nginx-prometheus-exporter: scrapes /stub_status, exposes :9113/metrics. Pinned
# release; the image is rebuilt to bump.
EXPORTER_VERSION="1.4.0"
curl -fsSL -o /tmp/nginx-exporter.tar.gz \
  "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${EXPORTER_VERSION}/nginx-prometheus-exporter_${EXPORTER_VERSION}_linux_amd64.tar.gz"
tar -xzf /tmp/nginx-exporter.tar.gz -C /usr/local/bin nginx-prometheus-exporter

cat >/etc/systemd/system/nginx-prometheus-exporter.service <<'UNIT'
[Unit]
Description=nginx-prometheus-exporter
After=nginx.service

[Service]
ExecStart=/usr/local/bin/nginx-prometheus-exporter --nginx.scrape-uri=http://127.0.0.1/stub_status --web.listen-address=:9113
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

nginx -t
systemctl enable nginx nginx-prometheus-exporter

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/kaddy /tmp/nginx-exporter.tar.gz
