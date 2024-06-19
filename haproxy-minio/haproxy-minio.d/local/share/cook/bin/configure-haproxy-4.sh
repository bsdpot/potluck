#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# make directories
mkdir -p /usr/local/etc/haproxy
mkdir -p /var/run/haproxy

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in 4 server haproxy.cfg
< "$TEMPLATEPATH/haproxy-4.cfg.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%domain%%${sep}$DOMAIN${sep}g" | \
  sed "s${sep}%%serverone%%${sep}$SERVERONE${sep}g" | \
  sed "s${sep}%%serveroneport%%${sep}$SERVERONEPORT${sep}g" | \
  sed "s${sep}%%servertwo%%${sep}$SERVERTWO${sep}g" | \
  sed "s${sep}%%servertwoport%%${sep}$SERVERTWOPORT${sep}g" | \
  sed "s${sep}%%serverthree%%${sep}$SERVERTHREE${sep}g" | \
  sed "s${sep}%%serverthreeport%%${sep}$SERVERTHREEPORT${sep}g" | \
  sed "s${sep}%%serverfour%%${sep}$SERVERFOUR${sep}g" | \
  sed "s${sep}%%serverfourport%%${sep}$SERVERFOURPORT${sep}g" \
  > /usr/local/etc/haproxy/haproxy.conf

# enable haproxy
sysrc haproxy_config="/usr/local/etc/haproxy/haproxy.conf"
service haproxy enable || true
