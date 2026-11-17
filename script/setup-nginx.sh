#!/usr/bin/env bash
# Configure Nginx as the public reverse proxy for the NestJS app on port 3000.
# Usage: sudo SERVER_NAME=api.example.com ./script/setup-nginx.sh
# For an IP-only setup, omit SERVER_NAME (Nginx will accept any Host header).

set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo: sudo SERVER_NAME=api.example.com $0" >&2
  exit 1
fi

server_name="${SERVER_NAME:-_}"
site_name="nest-api"
site_path="/etc/nginx/sites-available/${site_name}"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx

install -d -m 0755 /etc/nginx/sites-available /etc/nginx/sites-enabled

cat >"${site_path}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${server_name};

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sfn "${site_path}" "/etc/nginx/sites-enabled/${site_name}"

nginx -t
systemctl enable nginx
systemctl reload nginx

echo "Nginx is proxying HTTP requests to http://127.0.0.1:3000"
echo "Remember to allow inbound TCP port 80 in the EC2 security group."
