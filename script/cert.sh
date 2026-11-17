#!/usr/bin/env bash
# Install Certbot via Snap and obtain/configure a Let's Encrypt certificate for Nginx.
# Usage: sudo ./script/cert.sh example.com admin@example.com [www.example.com ...]
#
# Before running, point every supplied domain's DNS A/AAAA record at this server,
# configure Nginx with those domains in server_name, and allow inbound ports 80/443.

set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo: sudo $0 <domain> <email> [additional-domain ...]" >&2
  exit 1
fi

if [[ "$#" -lt 2 ]]; then
  echo "Usage: sudo $0 <domain> <email> [additional-domain ...]" >&2
  exit 1
fi

primary_domain="$1"
email="$2"
shift 2
domains=("${primary_domain}" "$@")

for domain in "${domains[@]}"; do
  if [[ ! "${domain}" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
    echo "Invalid domain: ${domain}" >&2
    exit 1
  fi
done

if [[ ! "${email}" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
  echo "Invalid email address: ${email}" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y snapd nginx
systemctl enable --now snapd.socket
systemctl enable --now nginx

# Certbot's recommended Snap installation method.
if ! snap list core >/dev/null 2>&1; then
  snap install core
fi
snap refresh core
if ! snap list certbot >/dev/null 2>&1; then
  snap install --classic certbot
fi
ln -sfn /snap/bin/certbot /usr/bin/certbot

nginx -t

certbot_args=(--nginx --non-interactive --agree-tos --email "${email}" --redirect)
for domain in "${domains[@]}"; do
  certbot_args+=(-d "${domain}")
done
certbot "${certbot_args[@]}"

# Snap installs Certbot's renewal timer; prove the renewal path works now.
certbot renew --dry-run

echo "HTTPS is configured for: ${domains[*]}"
