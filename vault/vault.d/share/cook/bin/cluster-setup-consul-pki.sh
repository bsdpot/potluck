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
mkdir -p /mnt/consulcerts
chown consul:wheel /mnt/consulcerts
cd /mnt/consulcerts
vault secrets list | grep -c "^consulpki/" || \
  vault secrets enable -path consulpki pki
vault secrets tune -max-lease-ttl=87600h consulpki
vault read consulpki/cert/ca || vault write -field=certificate \
  consulpki/root/generate/internal \
  common_name="$DATACENTER.consul" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^consulpki_int/" || \
  vault secrets enable -path consulpki_int pki
vault secrets tune -max-lease-ttl=43800h consulpki_int
vault read consulpki/cert/ca_int ||
  (
    vault write -format=json \
      consulpki_int/intermediate/generate/internal \
      common_name="$DATACENTER.consul Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr" > consulpki_intermediate.csr
    vault write -format=json consulpki/root/sign-intermediate \
      csr=@consulpki_intermediate.csr format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate" > intermediate.cert.pem
    vault write consulpki_int/intermediate/set-signed \
      certificate=@intermediate.cert.pem
  )
vault read consulpki_int/roles/consul-cluster || vault write \
  consulpki_int/roles/consul-cluster \
  allowed_domains="$DATACENTER.consul" \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^consul-tls-policy\$" ||
  vault policy write consul-tls-policy \
    "$TEMPLATEPATH/consul-tls-policy.hcl.in"
