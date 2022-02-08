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

if ! echo "$PROMSOURCE" | grep -qF ":"; then
  PROMSOURCE="$PROMSOURCE:9090"
fi

if ! echo "$PROMTLSNAME" | grep -qF "."; then
  PROMTLSNAME="$PROMTLSNAME.$DATACENTER.metrics"
fi

if ! echo "$LOKISOURCE" | grep -qF ":"; then
  LOKISOURCE="$LOKISOURCE:3100"
fi

if ! echo "$LOKITLSNAME" | grep -qF "."; then
  LOKITLSNAME="$LOKITLSNAME.$DATACENTER.metrics"
fi

< "$TEMPLATEPATH/grafanaproxy.conf.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" |\
  sed "s${sep}%%promsource%%${sep}$PROMSOURCE${sep}g" | \
  sed "s${sep}%%promtlsname%%${sep}$PROMTLSNAME${sep}g" | \
  sed "s${sep}%%lokisource%%${sep}$LOKISOURCE${sep}g" | \
  sed "s${sep}%%lokitlsname%%${sep}$LOKITLSNAME${sep}g" \
  > /usr/local/etc/nginx/grafanaproxy.conf

service nginx enable
sysrc nginx_profiles+="grafanaproxy"
sysrc nginx_grafanaproxy_configfile="/usr/local/etc/nginx/grafanaproxy.conf"
