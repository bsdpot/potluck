#!/bin/sh

# The "vault-servers" Vault group needs the "issue-nomad-client-cert" policy
# for this to work.

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
unset VAULT_FORMAT

. "${SCRIPTDIR}/lib.sh"

# real config dir
mkdir -p /usr/local/etc/nginx

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# Copy over consul-template template for Nomad certs
< "$TEMPLATEPATH/cluster-nomad.tpl.in" \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  > "/mnt/templates/nomad.tpl"

# Uncomment Nomad cert template in consul-template config
sed -i '' 's/^##nomadproxy##//g' /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl

# Copy over Nginx config for Nomad proxy
cp "$TEMPLATEPATH/cluster-nomadproxy.conf.in" \
  /usr/local/etc/nginx/nomadproxy.conf

service nginx enable
sysrc nginx_profiles+="nomadproxy"
sysrc nginx_nomadproxy_configfile="/usr/local/etc/nginx/nomadproxy.conf"

# Start Nomad proxy
timeout --foreground 120 \
  sh -c 'while ! service nginx status nomadproxy; do
    service nginx start nomadproxy || true; sleep 3;
  done'
