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
#sep=$'\001'

cp "$TEMPLATEPATH/nomadmetricsproxy.conf.in" \
  /usr/local/etc/nginx/nomadmetricsproxy.conf

service nginx enable
sysrc nginx_profiles+="nomadmetricsproxy"
sysrc nginx_nomadmetricsproxy_configfile=\
"/usr/local/etc/nginx/nomadmetricsproxy.conf"
