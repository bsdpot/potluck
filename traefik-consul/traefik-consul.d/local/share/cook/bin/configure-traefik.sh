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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/traefik.toml.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%uiflag%%${sep}$UIFLAG${sep}g" \
  > /usr/local/etc/traefik.toml

touch /var/log/traefik/traefik.log
touch /var/log/traefik/traefik-access.log
chown traefik:traefik /var/log/traefik/traefik.log
chown traefik:traefik /var/log/traefik/traefik-access.log

sysrc traefik_conf="/usr/local/etc/traefik.toml"
service traefik enable
