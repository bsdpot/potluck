#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=http://127.0.0.1:8200
cd /mnt/certs
vault secrets list | grep -c "^pki/" || vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault read pki/cert/ca || vault write -field=certificate \
  pki/root/generate/internal \
  common_name="global.vaultcluster" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^pki_int/" || \
  vault secrets enable -path pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault read pki/cert/ca_int ||
  (
    vault write -format=json \
      pki_int/intermediate/generate/internal \
      common_name="global.vaultcluster Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr" > pki_intermediate.csr
    vault write -format=json pki/root/sign-intermediate \
      csr=@pki_intermediate.csr format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate" > intermediate.cert.pem
    vault write pki_int/intermediate/set-signed \
      certificate=@intermediate.cert.pem
  )
vault read pki_int/roles/vault-cluster || vault write \
  pki_int/roles/vault-cluster \
  allowed_domains=global.vaultcluster,vault.service.consul \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^tls-policy\$" ||
  vault policy write tls-policy \
    "$TEMPLATEPATH/cluster-tls-policy.hcl.in"

TOKEN=$(vault token create -policy="tls-policy" -period=10m \
  -orphan -format json | jq -r ".auth.client_token")

JSON=$(VAULT_TOKEN="$TOKEN" \
       vault write -format=json pki_int/issue/vault-cluster \
         common_name="$NODENAME.global.vaultcluster" \
         ttl=10m \
         alt_names=localhost,\
active.vault.service.consul,standby.vault.service.consul \
         ip_sans="127.0.0.1,$IP" \
      )

(echo "$JSON" | jq -r ".data.ca_chain[]"; echo) >/mnt/certs/ca.crt
cat /mnt/certs/ca.crt ca_root.crt \
  >/mnt/certs/ca_chain.crt
echo "$JSON" | jq -r ".data.certificate" >/mnt/certs/agent.crt
(
  umask 177
  echo "$JSON" | jq -r ".data.private_key" >/mnt/certs/agent.key
)
"$SCRIPTDIR"/cluster-enable-vault-tls.sh
