#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/consulcerts/unwrapped.token ]; then
    TOKEN=$(< /mnt/consulcerts/credentials.json \
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
    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/client.key \
      -client-cert=/mnt/certs/client.crt \
      -format=json "$TOKEN" | \
      jq -r '.auth.client_token' > /mnt/consulcerts/unwrapped.token
    chown consul /mnt/consulcerts/*
fi
