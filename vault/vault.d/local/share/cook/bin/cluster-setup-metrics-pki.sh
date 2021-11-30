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

vault secrets list | grep -c "^metricspki/" || \
  vault secrets enable -path metricspki pki
vault secrets tune -max-lease-ttl=87600h metricspki
vault read metricspki/cert/ca || vault write -field=certificate \
  metricspki/root/generate/internal \
  common_name="$DATACENTER.metrics" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^metricspki_int/" || \
  vault secrets enable -path metricspki_int pki
vault secrets tune -max-lease-ttl=43800h metricspki_int
vault read metricspki/cert/ca_int ||
  (
    CSR=$(vault write -format=json \
      metricspki_int/intermediate/generate/internal \
      common_name="$DATACENTER.metrics Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr")
    CERT=$(vault write -format=json metricspki/root/sign-intermediate \
      csr="$CSR" format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate")
    vault write metricspki_int/intermediate/set-signed \
      certificate="$CERT"
  )
vault read metricspki_int/roles/metrics || vault write \
  metricspki_int/roles/metrics \
  allowed_domains="$DATACENTER.metrics" \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^metrics-tls-policy\$" ||
  vault policy write metrics-tls-policy \
    "$TEMPLATEPATH/metrics-tls-policy.hcl.in"
