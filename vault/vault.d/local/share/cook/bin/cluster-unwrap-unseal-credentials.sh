#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

if [ ! -s /mnt/unsealcerts/unwrapped.token ]; then
    UNSEALTOKEN=$(< /mnt/unsealcerts/credentials.json \
      jq -re .wrapped_token)
    < /mnt/unsealcerts/credentials.json \
      jq -re .cert >/mnt/unsealcerts/client.crt
    < /mnt/unsealcerts/credentials.json \
      jq -re .ca >>/mnt/unsealcerts/client.crt
    < /mnt/unsealcerts/credentials.json \
      jq -re .ca_root >/mnt/unsealcerts/ca_root.crt
    umask 177
    < /mnt/unsealcerts/credentials.json \
      jq -re .key >/mnt/unsealcerts/client.key
    HOME=/var/empty \
    vault unwrap -address="https://$UNSEALIP:8200" \
      -tls-server-name=server.global.vaultunseal \
      -ca-cert=/mnt/unsealcerts/ca_root.crt \
      -client-key=/mnt/unsealcerts/client.key \
      -client-cert=/mnt/unsealcerts/client.crt \
      -format=json "$UNSEALTOKEN" | \
      jq -r '.auth.client_token' > /mnt/unsealcerts/unwrapped.token
    chown vault /mnt/unsealcerts/client.crt
    chown vault /mnt/unsealcerts/client.key
fi
