#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

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
    umask 026
    < /mnt/consulcerts/credentials.json \
      jq -re .key >/mnt/consulcerts/agent.key
    < /mnt/consulcerts/credentials.json \
      jq -re .gossip_key >/mnt/consulcerts/gossip.key

    echo "{\"default\": $(< /mnt/consulcerts/credentials.json \
      jq -e .default_consul_token), \"agent\": $(\
      < /mnt/consulcerts/credentials.json \
      jq -e .agent_consul_token)}" >/mnt/consulcerts/acl-tokens.json

    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/client.key \
      -client-cert=/mnt/certs/client.crt \
      -format=json "$WRAPPED_TOKEN" | \
      jq -r '.auth.client_token' > /mnt/consulcerts/unwrapped.token
    chown consul /mnt/consulcerts/*
fi
