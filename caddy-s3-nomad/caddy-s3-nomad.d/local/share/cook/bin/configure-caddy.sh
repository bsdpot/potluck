#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# create directory for caddy config
mkdir -p /usr/local/etc/caddy/

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in custom caddyfile
< "$TEMPLATEPATH/Caddyfile.in" \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%server%%${sep}$SERVER${sep}g" | \
  sed "s${sep}%%bucket%%${sep}$BUCKET${sep}g" | \
  sed "s${sep}%%email%%${sep}$EMAIL${sep}g" \
  > /usr/local/etc/caddy/Caddyfile

# enable nginx
service caddy enable || true
