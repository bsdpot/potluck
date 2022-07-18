#!/bin/sh

## shellcheck disable=SC1091
#. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# real config dir
mkdir -p /usr/local/etc/nginx

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/prometheusproxy.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" \
  > /usr/local/etc/nginx/prometheusproxy.conf

service nginx enable
sysrc nginx_profiles+="prometheusproxy"
sysrc nginx_prometheusproxy_configfile="/usr/local/etc/nginx/prometheusproxy.conf"
