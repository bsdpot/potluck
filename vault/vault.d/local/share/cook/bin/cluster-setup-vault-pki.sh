#!/bin/sh

: "${BTTL=3h}" # ttl of tokens

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=http://127.0.0.1:8200

if [ -z "$NODENAME" ]; then
  1>&2 echo "NODENAME unset"
  exit 1
fi

. "${SCRIPTDIR}/lib.sh"

create_root_pki "vaultpki" "global.vaultcluster root"
create_int_pki "vaultpki" "vaultpki_int" "global.vaultcluster intermediate"

# Create vault-server role for issuing vault server certs
create_pki_role "vaultpki_int" "vault-server" \
  "{{identity.entity.metadata.nodename}}.global.vaultcluster" \
  active.vault.service.consul \
  standby.vault.service.consul \
  vault.service.consul

export VAULT_FORMAT=json

# Create issue-vault-server-cert policy, which grants access to
# issue vault-server role
vault policy write issue-vault-server-cert - <<-EOF
	path "vaultpki_int/issue/vault-server" {
	  capabilities = ["update"]
	}
	path "vaultpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

create_pki_role "vaultpki_int" "vault-client" \
  "{{identity.entity.metadata.nodename}}.global.vaultcluster" \
  "client.global.vaultcluster"

# Create issue-vault-client-cert policy, which grants access to
# issue vault-client role
vault policy write issue-vault-client-cert - <<-EOF
	path "vaultpki_int/issue/vault-client" {
	  capabilities = ["update"]
	}
	path "vaultpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

create_pki_role "vaultpki_int" "vault-computenode" \
  "{{identity.entity.metadata.nodename}}.global.vaultcluster" \
  "computenode.global.vaultcluster"

# Create issue-vault-computenode-cert policy, which grants access to
# issue vault-client role
vault policy write issue-vault-computenode-cert - <<-EOF
	path "vaultpki_int/issue/vault-computenode" {
	  capabilities = ["update"]
	}
	path "vaultpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create entity for this node
ENTITY_NAME="$NODENAME-vault"
entity_id=$(create_id_entity "$ENTITY_NAME" "$NODENAME")

# Create entity-alias mapping to the entity that was just created
create_id_entity_alias "$ENTITY_NAME" "$entity_id" "token" \
  'desc="'"$ENTITY_NAME"' alias"' >/dev/null

# Create/update group with entity being the sole member (others will follow)
create_id_group "vault-servers" \
    "issue-vault-server-cert" \
    >/dev/null
add_id_group_member "vault-servers" "$entity_id"

# Create token role, which will be applied when issuing
# the token
vault write auth/token/roles/cert-issuer \
  disallowed_policies="root" \
  allowed_entity_aliases="*" \
  token_explicit_max_ttl=0 \
  token_period="$BTTL" \
  orphan=true \
  renewable=true

# Issue token using the correct role and entity_alias specified above
TOKEN=$(vault token create \
  -display-name "$ENTITY_NAME token from pki setup - not renewed" \
  -role "cert-issuer" \
  -entity-alias "$ENTITY_NAME" \
  -policy default | jq -er ".auth.client_token")

##############################

JSON=$(VAULT_TOKEN="$TOKEN" \
       vault write vaultpki_int/issue/vault-server \
         common_name="$NODENAME.global.vaultcluster" \
         alt_names=localhost,\
active.vault.service.consul,standby.vault.service.consul,vault.service.consul \
         ip_sans="127.0.0.1,$IP" \
      )

(echo "$JSON" | jq -er ".data.certificate"; echo) >/mnt/vaultcerts/agent.crt
(echo "$JSON" | jq -er ".data.ca_chain[]"; echo) >>/mnt/vaultcerts/agent.crt
(
  umask 177
  echo "$JSON" | jq -er ".data.private_key" >/mnt/vaultcerts/agent.key
)
get_pki_ca "vaultpki" >/mnt/vaultcerts/ca_root.crt

chown vault /mnt/vaultcerts/agent.crt
chown vault /mnt/vaultcerts/agent.key

"$SCRIPTDIR"/cluster-enable-vault-tls.sh
