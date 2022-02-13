#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

if [ ! -s /mnt/nomadcerts/unwrapped.token ]; then
    WRAPPED_TOKEN=$(< /mnt/nomadcerts/credentials.json \
      jq -re .wrapped_token)
    < /mnt/nomadcerts/credentials.json \
      jq -re .cert >/mnt/nomadcerts/agent.crt
    < /mnt/nomadcerts/credentials.json \
      jq -re .ca >/mnt/nomadcerts/ca.crt
    < /mnt/nomadcerts/credentials.json \
      jq -re .ca_chain >/mnt/nomadcerts/ca_chain.crt
    < /mnt/nomadcerts/credentials.json \
      jq -re .ca_root >>/mnt/nomadcerts/ca_chain.crt
    < /mnt/nomadcerts/credentials.json \
      jq -re .ca_root >/mnt/nomadcerts/ca_root.crt
    umask 177
    < /mnt/nomadcerts/credentials.json \
      jq -re .key >/mnt/nomadcerts/agent.key

    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/certs/ca_chain.crt \
      -client-key=/mnt/certs/client.key \
      -client-cert=/mnt/certs/client.crt \
      -format=json "$WRAPPED_TOKEN" | \
      jq -r '.auth.client_token' > /mnt/nomadcerts/unwrapped.token
fi
