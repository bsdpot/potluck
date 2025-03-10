#!/bin/sh

# The "consul-servers" Vault group needs the "issue-nomad-client-cert" policy
# for this to work.

# shellcheck disable=SC1091
. /root/.env.cook

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

# Copy over consul-template template for Nomad certs
< "$TEMPLATEPATH/nomad.tpl.in" \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  > "/mnt/templates/nomad.tpl"

# Uncomment Nomad cert template in consul-template config
sed -i '' 's/^##nomadproxy##//g' /usr/local/etc/consul-template.d/consul-template.hcl

# Copy over Nginx config for Nomad proxy
cp "$TEMPLATEPATH/nomadproxy.conf.in" \
  /usr/local/etc/nginx/nomadproxy.conf

service nginx enable
sysrc nginx_profiles+="nomadproxy"
sysrc nginx_nomadproxy_configfile="/usr/local/etc/nginx/nomadproxy.conf"

# Start Nomad proxy
timeout --foreground 120 \
  sh -c 'while ! service nginx status nomadproxy; do
    service nginx start nomadproxy || true; sleep 3;
  done'
