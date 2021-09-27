#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/certs/agent.crt
export VAULT_CLIENT_KEY=/mnt/certs/agent.key
export VAULT_CACERT=/mnt/certs/ca_chain.crt

vault secrets list | grep -c "^nomadpki/" || \
  vault secrets enable -path nomadpki pki
vault secrets tune -max-lease-ttl=87600h nomadpki
vault read nomadpki/cert/ca || vault write -field=certificate \
  nomadpki/root/generate/internal \
  common_name="global.nomad" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^nomadpki_int/" || \
  vault secrets enable -path nomadpki_int pki
vault secrets tune -max-lease-ttl=43800h nomadpki_int
vault read nomadpki/cert/ca_int ||
  (
    CSR=$(vault write -format=json \
      nomadpki_int/intermediate/generate/internal \
      common_name="global.nomad Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr")
    CERT=$(vault write -format=json nomadpki/root/sign-intermediate \
      csr="$CSR" format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate")
    vault write nomadpki_int/intermediate/set-signed \
      certificate="$CERT"
  )
vault read nomadpki_int/roles/nomad-cluster || vault write \
  nomadpki_int/roles/nomad-cluster \
  allowed_domains="global.nomad" \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^nomad-tls-policy\$" ||
  vault policy write nomad-tls-policy \
    "$TEMPLATEPATH/nomad-tls-policy.hcl.in"
