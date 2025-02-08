#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

# make directories
mkdir -p /usr/local/etc/haproxy
mkdir -p /var/run/haproxy

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in 3 server haproxy.cfg
< "$TEMPLATEPATH/haproxy-3.cfg.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%serverone%%${sep}$SERVERONE${sep}g" | \
  sed "s${sep}%%serveroneport%%${sep}$SERVERONEPORT${sep}g" | \
  sed "s${sep}%%servertwo%%${sep}$SERVERTWO${sep}g" | \
  sed "s${sep}%%servertwoport%%${sep}$SERVERTWOPORT${sep}g" | \
  sed "s${sep}%%serverthree%%${sep}$SERVERTHREE${sep}g" | \
  sed "s${sep}%%serverthreeport%%${sep}$SERVERTHREEPORT${sep}g" \
  > /usr/local/etc/haproxy/haproxy.conf

# enable haproxy
sysrc haproxy_config="/usr/local/etc/haproxy/haproxy.conf"
service haproxy enable || true
