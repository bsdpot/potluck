#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

service consul-template onestatus && service consul-template onestop
UNWRAP_TOKEN=$(VAULT_CACERT=/mnt/unsealcerts/ca_chain.crt \
  vault token create -policy="tls-policy" -period=10m \
  -wrap-ttl=240s -orphan -format json | jq -r ".wrap_info.token")

mkdir -p /usr/local/etc/consul-template.d

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

cp "$TEMPLATEPATH/unseal-consul-template.hcl.in" \
  /usr/local/etc/consul-template.d/consul-template.hcl
chmod 600 \
  /usr/local/etc/consul-template.d/consul-template.hcl
echo "s${sep}%%token%%${sep}$UNWRAP_TOKEN${sep}" | sed -f - -i '' \
  /usr/local/etc/consul-template.d/consul-template.hcl

sysrc consul_template_syslog_output_enable=YES

for name in unseal-agent.crt unseal-agent.key unseal-ca.crt; do
    < "$TEMPLATEPATH/$name.tpl.in" \
      sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
      sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
      sed "s${sep}%%attl%%${sep}$ATTL${sep}g" | \
      sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
      > "/mnt/templates/$name.tpl"
done

service consul-template onestart
