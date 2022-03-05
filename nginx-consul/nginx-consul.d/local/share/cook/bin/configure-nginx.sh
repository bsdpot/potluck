#!/bin/sh

## shellcheck disable=SC1091
#. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH="$SCRIPTDIR/../templates"
CONFIG_TMPL="/mnt/nginx.conf.in"

mkdir -p /usr/local/etc/nginx/certs
mkdir -p /var/run/nginx

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

[ -e "$CONFIG_TMPL" ] || CONFIG_TMPL="$TEMPLATEPATH/nginx.conf.default.in"

< "$CONFIG_TMPL" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/nginx/nginx.conf

# enable nginx
service nginx enable
sysrc nginx_profiles+="nginx"
sysrc nginx_vaultproxy_configfile="/usr/local/etc/nginx/nginx.conf"
