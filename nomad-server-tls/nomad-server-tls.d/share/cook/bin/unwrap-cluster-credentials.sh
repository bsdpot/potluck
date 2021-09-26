#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/certs/unwrapped.token ]; then
    UNSEALTOKEN=$(< /mnt/certs/credentials.json \
      jq -re .wrapped_token)
    < /mnt/certs/credentials.json \
      jq -re .cert >/mnt/certs/client.crt
    < /mnt/certs/credentials.json \
      jq -re .ca >/mnt/certs/ca.crt
    < /mnt/certs/credentials.json \
      jq -re .ca_chain >/mnt/certs/ca_chain.crt
    < /mnt/certs/credentials.json \
      jq -re .ca_root >>/mnt/certs/ca_chain.crt
    < /mnt/certs/credentials.json \
      jq -re .ca_root >/mnt/certs/ca_root.crt
    umask 177
    < /mnt/certs/credentials.json \
      jq -re .key >/mnt/certs/client.key
    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/client.key \
      -client-cert=/mnt/certs/client.crt \
      -format=json "$UNSEALTOKEN" | \
      jq -r '.auth.client_token' > /mnt/certs/unwrapped.token
    chown nomad /mnt/certs/*
fi
