#!/usr/bin/env bash
# Install the server dependencies and configure the local PostgreSQL database.
# Usage: sudo ./script/setup-package.sh
#
# This script targets Ubuntu/Debian hosts. It can be safely re-run.

set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo: sudo $0" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Unsupported operating system: /etc/os-release is unavailable." >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID}" != "ubuntu" && "${ID}" != "debian" && "${ID_LIKE:-}" != *"debian"* ]]; then
  echo "This script supports Ubuntu/Debian hosts only." >&2
  exit 1
fi

database_name="awsnestcicd"
database_user="postgres"
database_password="password"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg postgresql postgresql-contrib

# Install the current Node.js LTS release, which includes npm.
install -d -m 0755 /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/nodesource.gpg ]]; then
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
fi
node_major=22
printf 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_%s.x nodistro main\n' "${node_major}" \
  > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs

systemctl enable --now postgresql

# `postgres` is the local administrative role created by the package. Configure
# its password and ensure the database exists with that role as its owner.
runuser -u postgres -- psql --set=ON_ERROR_STOP=1 \
  --command="ALTER ROLE ${database_user} WITH LOGIN PASSWORD '${database_password}';"

if ! runuser -u postgres -- psql --tuples-only --no-align \
  --command="SELECT 1 FROM pg_database WHERE datname = '${database_name}'" \
  | grep -qx '1'; then
  runuser -u postgres -- createdb --owner="${database_user}" "${database_name}"
fi

npm install --global pm2

cat <<EOF
Setup complete.

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=${database_name}
DATABASE_USER=${database_user}
DATABASE_PASSWORD=${database_password}

Installed versions:
  node $(node --version)
  npm  $(npm --version)
  pm2  $(pm2 --version)
EOF
