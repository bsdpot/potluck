#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

# shellcheck disable=SC3013
if [ ! -s /mnt/vaultcerts/unwrapped.token ] || \
   [ /mnt/vaultcerts/unwrapped.token -ot \
     /mnt/vaultcerts/credentials.json ]; then
    UNSEALTOKEN=$(< /mnt/vaultcerts/credentials.json \
      jq -re .wrapped_token)
    < /mnt/vaultcerts/credentials.json \
      jq -re .cert >/mnt/vaultcerts/client.crt
    < /mnt/vaultcerts/credentials.json \
      jq -re .ca >>/mnt/vaultcerts/client.crt
    < /mnt/vaultcerts/credentials.json \
      jq -re .ca >/mnt/vaultcerts/ca.crt
    < /mnt/vaultcerts/credentials.json \
      jq -re .ca_root >/mnt/vaultcerts/ca_root.crt
    umask 177
    < /mnt/vaultcerts/credentials.json \
      jq -re .key >/mnt/vaultcerts/client.key
    HOME=/var/empty \
    vault unwrap -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/client.key \
      -client-cert=/mnt/vaultcerts/client.crt \
      -format=json "$UNSEALTOKEN" | \
      jq -r '.auth.client_token' > /mnt/vaultcerts/unwrapped.token
fi
