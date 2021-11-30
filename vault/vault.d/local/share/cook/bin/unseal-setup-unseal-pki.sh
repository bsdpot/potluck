#!/bin/sh

: "${TTL:=10m}"

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=http://127.0.0.1:8200

cd /mnt/unsealcerts
vault secrets list | grep -c "^pki/" || vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault read pki/cert/ca || vault write -field=certificate \
  pki/root/generate/internal \
  common_name="global.vaultunseal" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^pki_int/" || \
  vault secrets enable -path pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault read pki/cert/ca_int ||
  (
    vault write -format=json \
      pki_int/intermediate/generate/internal \
      common_name="global.vaultunseal Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr" > pki_intermediate.csr
    vault write -format=json pki/root/sign-intermediate \
      csr=@pki_intermediate.csr format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate" > intermediate.cert.pem
    vault write pki_int/intermediate/set-signed \
      certificate=@intermediate.cert.pem
  )
vault read pki_int/roles/vault-unseal || vault write \
  pki_int/roles/vault-unseal \
  allowed_domains=global.vaultunseal \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^tls-policy\$" ||
  vault policy write tls-policy "$TEMPLATEPATH/unseal-tls-policy.hcl.in"

TOKEN=$(vault token create -policy="tls-policy" -period="$TTL" \
  -orphan -format json | jq -r ".auth.client_token")

JSON=$(VAULT_TOKEN="$TOKEN" \
       vault write -format=json pki_int/issue/vault-unseal \
         common_name=server.global.vaultunseal \
         ttl="$TTL" \
         alt_names=localhost \
         ip_sans=127.0.0.1 \
      )

(echo "$JSON" | jq -r ".data.ca_chain[]"; echo) >/mnt/unsealcerts/ca.crt
cat /mnt/unsealcerts/ca.crt ca_root.crt \
  >/mnt/unsealcerts/ca_chain.crt
echo "$JSON" | jq -r ".data.certificate" >/mnt/unsealcerts/agent.crt
echo "$JSON" | jq -r ".data.private_key" >/mnt/unsealcerts/agent.key

chown vault /mnt/unsealcerts/*
sysrc vault_config=/usr/local/etc/vault.hcl
service vault restart
echo "\
Vault restarted, please unseal, then run \
$SCRIPTDIR/unseal-start-consul-template.sh"
