#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/consulcerts/gossip.key ]; then
    CREDENTIALS_TOKEN=$(< /mnt/consulcerts/credentials.json \
      jq -re .credentials_token)

    umask 177
    HOME=/var/empty \
    VAULT_TOKEN="$CREDENTIALS_TOKEN" \
    vault read -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/client.key \
      -client-cert=/mnt/vaultcerts/client.crt \
      -format=json "cubbyhole/consul" |
      jq -r '.data.gossip_key' > /mnt/consulcerts/gossip.key
fi
