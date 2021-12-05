#!/bin/sh

: "${CERT_MAX_TTL=768h}"

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates
mkdir -p /mnt/postgrescerts
cd /mnt/postgrescerts
export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/certs/agent.crt
export VAULT_CLIENT_KEY=/mnt/certs/agent.key
export VAULT_CACERT=/mnt/certs/ca_chain.crt

vault secrets list | grep -c "^postgrespki/" || \
  vault secrets enable -path postgrespki pki
vault secrets tune -max-lease-ttl=87600h postgrespki
vault read postgrespki/cert/ca || vault write -field=certificate \
  postgrespki/root/generate/internal \
  common_name="global.postgres" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^postgrespki_int/" || \
  vault secrets enable -path postgrespki_int pki
vault secrets tune -max-lease-ttl=43800h postgrespki_int
vault read postgrespki_int/cert/ca ||
  (
    CSR=$(vault write -format=json \
      postgrespki_int/intermediate/generate/internal \
      common_name="global.postgres Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr")
    CERT=$(vault write -format=json postgrespki/root/sign-intermediate \
      csr="$CSR" format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate")
    vault write postgrespki_int/intermediate/set-signed \
      certificate="$CERT"
  )
vault read postgrespki_int/roles/postgres-cluster || vault write \
  postgrespki_int/roles/postgres-cluster \
  allowed_domains="global.postgres,postgresql.service.consul" \
  allow_subdomains=true max_ttl="$CERT_MAX_TTL" \
  require_cn=false generate_lease=true
vault policy list | grep -c "^postgres-tls-policy\$" ||
  vault policy write postgres-tls-policy \
    "$TEMPLATEPATH/postgres-tls-policy.hcl.in"
