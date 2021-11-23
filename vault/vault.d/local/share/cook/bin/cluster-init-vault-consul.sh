#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

if [ ! -s /mnt/consulcerts/unwrapped.token ]; then
    WRAPPED_TOKEN=$(< /mnt/consulcerts/credentials.json \
      jq -re .wrapped_token)
    < /mnt/consulcerts/credentials.json \
      jq -re .cert >/mnt/consulcerts/agent.crt
    < /mnt/consulcerts/credentials.json \
      jq -re .ca >/mnt/consulcerts/ca.crt
    < /mnt/consulcerts/credentials.json \
      jq -re .ca_chain >/mnt/consulcerts/ca_chain.crt
    < /mnt/consulcerts/credentials.json \
      jq -re .ca_root >>/mnt/consulcerts/ca_chain.crt
    < /mnt/consulcerts/credentials.json \
      jq -re .ca_root >/mnt/consulcerts/ca_root.crt
    umask 177
    < /mnt/consulcerts/credentials.json \
      jq -re .key >/mnt/consulcerts/agent.key
    < /mnt/consulcerts/credentials.json \
      jq -re .gossip_key >/mnt/consulcerts/gossip.key
    < /mnt/consulcerts/credentials.json \
      jq -re .vault_service_token >/mnt/consulcerts/vault_service.token
    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/agent.key \
      -client-cert=/mnt/certs/agent.crt \
      -format=json "$WRAPPED_TOKEN" | \
      jq -r '.auth.client_token' > /mnt/consulcerts/unwrapped.token
    chown consul /mnt/consulcerts/*
fi

GOSSIPKEY="$(cat /mnt/consulcerts/gossip.key)"
TOKEN="$(cat /mnt/consulcerts/unwrapped.token)"
VAULT_SERVICE_TOKEN="$(cat /mnt/consulcerts/vault_service.token)"

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/cluster-consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$CONSULSERVERS${sep}g" \
  > /usr/local/etc/consul.d/agent.hcl

chown consul /usr/local/etc/consul.d/agent.hcl
chmod 600 /usr/local/etc/consul.d/agent.hcl
echo "s${sep}%%gossipkey%%${sep}$GOSSIPKEY${sep}g" | sed -i '' -f - \
  /usr/local/etc/consul.d/agent.hcl

if ! service consul-template-consul onestatus; then
    echo "Writing consul-template-consul config"
    mkdir -p /usr/local/etc/consul-template-consul.d
    cp "$TEMPLATEPATH/cluster-consul-template-consul.hcl.in" \
      /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl
    chmod 600 \
      /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl
    echo "s${sep}%%token%%${sep}$TOKEN${sep}" | sed -i '' -f - \
      /usr/local/etc/consul-template-consul.d/consul-template-consul.hcl

    for name in consul-agent.crt consul-agent.key consul-ca.crt; do
        < "$TEMPLATEPATH/cluster-$name.tpl.in" \
          sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
          sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
          sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
          sed "s${sep}%%attl%%${sep}$ATTL${sep}g" | \
          sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
          > "/mnt/templates/$name.tpl"
    done

    echo "Enabling and starting consul-template"
    sysrc consul_template_consul_syslog_output_enable=YES
    service consul-template-consul enable
    service consul-template-consul start
fi

echo "s${sep}%%consultoken%%${sep}$VAULT_SERVICE_TOKEN${sep}g" |
  sed -i '' -f - /usr/local/etc/vault.hcl

service consul restart || true
sleep 2
service vault restart || true
