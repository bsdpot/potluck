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

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

## start varnish
mkdir -p /usr/local/etc/varnish/

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in varnish default.vcl
< "$TEMPLATEPATH/default.vcl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/varnish/default.vcl

# set permissions
chmod 644 /usr/local/etc/varnish/default.vcl
chown -R varnish:varnish /usr/local/etc/varnish/

# enable varnish
service varnishd enable || true
sysrc varnishd_listen="$IP:8080"
sysrc varnishd_admin="$IP:8081"
sysrc varnishd_config="/usr/local/etc/varnish/default.vcl"
sysrc varnishd_storage="default,2000M"
