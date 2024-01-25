#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

LOCAL_VAULT="https://127.0.0.1:8200"

echo "Getting local consul-template token"
CLUSTER_PKI_TOKEN_JSON=$(\
  vault token create \
    -address="$LOCAL_VAULT" \
    -ca-cert=/mnt/vaultcerts/ca_root.crt \
    -display-name "$NODENAME consul-template token" \
    -role "cert-issuer" \
    -entity-alias "$NODENAME-vault" \
    -policy default \
    -format json)
CLUSTER_PKI_TOKEN=$(echo "$CLUSTER_PKI_TOKEN_JSON" |\
  jq -r ".auth.client_token")

echo "Writing consul-template config"
mkdir -p /usr/local/etc/consul-template.d

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

cp "$TEMPLATEPATH/cluster-consul-template.hcl.in" \
  /usr/local/etc/consul-template.d/consul-template.hcl
chmod 600 \
  /usr/local/etc/consul-template.d/consul-template.hcl
echo "s${sep}%%token%%${sep}$CLUSTER_PKI_TOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/consul-template.d/consul-template.hcl

< "$TEMPLATEPATH/cluster-vault.tpl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" \
  > "/mnt/templates/cluster-vault.tpl"

echo "Enabling consul-template"
sysrc consul_template_syslog_output_enable=YES
service consul-template enable
