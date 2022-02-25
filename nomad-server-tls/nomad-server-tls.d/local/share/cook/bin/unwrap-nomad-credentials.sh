#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# everything we write matters
umask 177

if [ ! -s /mnt/nomadcerts/unwrapped.token ]; then
    WRAPPED_TOKEN=$(< /mnt/nomadcerts/credentials.json \
      jq -re .wrapped_token)

    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/client.key \
      -client-cert=/mnt/vaultcerts/client.crt \
      -format=json "$WRAPPED_TOKEN" | \
      jq -r '.auth.client_token' > /mnt/nomadcerts/unwrapped.token
fi

if [ ! -s /mnt/nomadcerts/gossip.key ]; then
    CREDENTIALS_TOKEN=$(< /mnt/nomadcerts/credentials.json \
      jq -re .credentials_token)

    DATA=$(
    HOME=/var/empty \
    VAULT_TOKEN="$CREDENTIALS_TOKEN" \
    vault read -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/client.key \
      -client-cert=/mnt/vaultcerts/client.crt \
      -format=json "cubbyhole/nomad" |
      jq -e '.data')

    echo "$DATA" | jq -re '.gossip_key' >/mnt/nomadcerts/gossip.key
    echo "$DATA" | jq -re '.nomad_service_token' \
      >/mnt/nomadcerts/nomad_service.token
fi
