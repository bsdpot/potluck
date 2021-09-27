#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_CACERT=/mnt/unsealcerts/ca_chain.crt
vault audit list | grep -c "^file/" ||
  vault audit enable file file_path=/mnt/vault/audit.log
vault secrets list | grep -c "^transit/" ||
  vault secrets enable transit
vault read transit/keys/autounseal ||
  vault write -f transit/keys/autounseal
vault policy list | grep -c "^autounseal\$" ||
  vault policy write autounseal \
  /usr/local/share/cook/templates/unseal-autounseal-policy.hcl.in
vault auth tune -default-lease-ttl=1h \
  -max-lease-ttl=18240h /token
