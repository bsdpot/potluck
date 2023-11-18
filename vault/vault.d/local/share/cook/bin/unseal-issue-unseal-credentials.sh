#!/bin/sh

# environment defaults
: "${TOKEN_TTL=2h}"
: "${TOKEN_WRAP_TTL=10m}"

CERT_NODENAME="$1"
CERT_TTL="$2"

trap "echo \$STEP failed" EXIT

if [ -z "$CERT_NODENAME" ]; then
  2>&1 echo "Usage: $0 cert_nodename [ttl]"
  exit 1
fi

if [ -z "$CERT_TTL" ]; then
  CERT_TTL="8h"
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_CACERT=/mnt/unsealcerts/ca_root.crt
export VAULT_FORMAT=json
STEP="Issue token"
TOKEN=$(vault token create -policy=autounseal \
  -policy=unseal-tls-policy -wrap-ttl="$TOKEN_WRAP_TTL" -ttl="$TOKEN_TTL" \
  | jq -e ".wrap_info.token")
STEP="Get root CA"
CA_ROOT=$(vault read unsealpki/cert/ca | jq -e ".data.certificate")
STEP="Issue Client Certificate"
CERT_JSON=$(vault write unsealpki_int/issue/vault-unseal \
  common_name="$CERT_NODENAME.global.vaultunseal" \
  ttl="$CERT_TTL" alt_names=localhost ip_sans=127.0.0.1)

STEP="Parse Client Certificate"
CERT=$(echo "$CERT_JSON" | jq -e ".data.certificate")
KEY=$(echo "$CERT_JSON" | jq -e ".data.private_key")
CA=$(echo "$CERT_JSON" | jq -e ".data.issuing_ca")
CA_CHAIN=$(
  echo "$CERT_JSON" | jq -e '.data.ca_chain | join("\n")'
)

STEP="Assemble response"
echo "{
  \"wrapped_token\": $TOKEN,
  \"cert\": $CERT,
  \"key\": $KEY,
  \"ca\": $CA,
  \"ca_chain\": $CA_CHAIN,
  \"ca_root\": $CA_ROOT
}"  | jq

trap - EXIT
