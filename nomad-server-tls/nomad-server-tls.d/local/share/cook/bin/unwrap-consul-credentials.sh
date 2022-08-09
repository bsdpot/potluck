#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3013
if [ ! -s /mnt/consulcerts/gossip.key ] || \
   [ /mnt/consulcerts/gossip.key -ot \
     /mnt/consulcerts/credentials.json ]; then
    CREDENTIALS_TOKEN=$(< /mnt/consulcerts/credentials.json \
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
      -format=json "cubbyhole/consul" |
      jq -e '.data')

    echo "$DATA" | jq -re '.gossip_key' >/mnt/consulcerts/gossip.key
    DNS_TOKEN=$(echo "$DATA" | jq -re '.dns_request_token')
    AGENT_TOKEN=$(echo "$DATA" | jq -re '.agent_consul_token')

    # shellcheck disable=SC3037
    echo -n '{"default":"'"$DNS_TOKEN"'","agent":"'"$AGENT_TOKEN"'"}' \
      >/mnt/consulcerts/acl-tokens.json
fi
