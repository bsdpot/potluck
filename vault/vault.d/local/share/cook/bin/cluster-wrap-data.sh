#!/bin/sh

# Take data from stdin, and write it to the
# cubbyhole of a short-lived token

NAME="$1"
TTL="$2"
USE_LIMIT="$3"

trap "echo \$STEP failed" EXIT

if [ -z "$NAME" ]; then
    2>&1 echo "Usage: $0 name_in_cubbyhole [ttl] [num_uses]"
    2>&1 echo "Reads JSON from stdin"
    exit 1
fi

if [ -z "$TTL" ]; then
    TTL="10m"
fi

if [ -z "$USE_LIMIT" ]; then
    USE_LIMIT="1"
fi

# increase USE_LIMIT by one, so we can always do the write
# operation
USE_LIMIT=$(("$USE_LIMIT" + 1))

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
export VAULT_FORMAT=table
STEP="Issue token"
# shellcheck disable=SC2086
TOKEN=$(vault token create -ttl "$TTL" \
        -display-name "cubbyhole data wrap" \
        -use-limit "$USE_LIMIT" \
        -field token)
VAULT_TOKEN="$TOKEN" vault write "cubbyhole/$NAME" - >/dev/null

STEP="Assemble response"
echo "{
  \"token\": \"$TOKEN\"
}"  | jq

trap - EXIT
