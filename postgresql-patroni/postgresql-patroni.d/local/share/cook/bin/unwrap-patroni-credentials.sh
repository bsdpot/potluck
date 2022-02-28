#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

if [ ! -s /mnt/patronicerts/superuser.pass ]; then
    CREDENTIALS_TOKEN=$(< /mnt/patronicerts/credentials.json \
      jq -re .credentials_token)

    umask 177

    DATA=$(
    HOME=/var/empty \
    VAULT_TOKEN="$CREDENTIALS_TOKEN" \
    vault read -address="https://active.vault.service.consul:8200" \
      -tls-server-name=active.vault.service.consul \
      -ca-cert=/mnt/vaultcerts/ca_root.crt \
      -client-key=/mnt/vaultcerts/client.key \
      -client-cert=/mnt/vaultcerts/client.crt \
      -format=json "cubbyhole/patroni" |
      jq -e '.data')


    echo "$DATA" | jq -re '.postgres_service_token' \
      >/mnt/patronicerts/postgres_service.token
    for name in admin exporter replicator superuser; do
        echo "$DATA" | jq -re ".${name}_key" >"/mnt/patronicerts/$name.pass"
    done
fi
