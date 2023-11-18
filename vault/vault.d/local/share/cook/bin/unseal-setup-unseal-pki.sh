#!/bin/sh

: "${TTL=2h}"

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=http://127.0.0.1:8200

cd /mnt/unsealcerts
vault secrets list | grep -c "^unsealpki/" || \
  vault secrets enable -path unsealpki pki
vault secrets tune -max-lease-ttl=87600h unsealpki
vault read unsealpki/cert/ca || vault write -field=certificate \
  unsealpki/root/generate/internal \
  common_name="global.vaultunseal" ttl=87600h > ca_root.crt
vault secrets list | grep -c "^unsealpki_int/" || \
  vault secrets enable -path unsealpki_int pki
vault secrets tune -max-lease-ttl=43800h unsealpki_int
vault read unsealpki/cert/ca_int ||
  (
    CSR=$(vault write -format=json \
      unsealpki_int/intermediate/generate/internal \
      common_name="global.vaultunseal Intermediate Authority" \
      ttl="43800h" | jq -r ".data.csr")
    INT_CERT=$(echo "$CSR" | \
      vault write -format=json unsealpki/root/sign-intermediate \
      csr=- format=pem_bundle \
      ttl="43800h" | jq -r ".data.certificate")
    echo "$INT_CERT" | vault write unsealpki_int/intermediate/set-signed \
      certificate=-
  )
vault read unsealpki_int/roles/vault-unseal || vault write \
  unsealpki_int/roles/vault-unseal \
  allowed_domains=global.vaultunseal \
  allow_subdomains=true max_ttl=86400s \
  require_cn=false generate_lease=true
vault policy list | grep -c "^unseal-tls-policy\$" ||
  vault policy write unseal-tls-policy - <<-EOF
	path "unsealpki_int/issue/vault-unseal" {
	  capabilities = ["update"]
	}
	path "unsealpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

TOKEN=$(vault token create -policy="unseal-tls-policy" -period="$TTL" \
  -orphan -format json | jq -r ".auth.client_token")

JSON=$(VAULT_TOKEN="$TOKEN" \
       vault write -format=json unsealpki_int/issue/vault-unseal \
         common_name=server.global.vaultunseal \
         ttl="$TTL" \
         alt_names=localhost \
         ip_sans=127.0.0.1 \
      )

(echo "$JSON" | jq -r ".data.certificate"; echo) >/mnt/unsealcerts/agent.crt
(echo "$JSON" | jq -r ".data.ca_chain[]"; echo) >>/mnt/unsealcerts/agent.crt
echo "$JSON" | jq -r ".data.private_key" >/mnt/unsealcerts/agent.key

sysrc vault_config=/usr/local/etc/vault.hcl
service vault restart
echo "\
Vault restarted, please unseal, then run \
$SCRIPTDIR/unseal-start-consul-template.sh"
