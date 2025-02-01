#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
unset VAULT_FORMAT

. "${SCRIPTDIR}/lib.sh"

create_root_pki "postgrespki" "global.postgres root"
create_int_pki "postgrespki" "postgrespki_int" "global.postgres intermediate"

# Create postgres-server role for issuing postgres server certs
create_pki_role "postgrespki_int" "postgres-server" \
  "{{identity.entity.metadata.nodename}}.global.postgres" \
  master.postgresql.service.consul \
  replica.postgresql.service.consul \
  standby-leader.postgresql.service.consul \
  backup-node.postgresql.service.consul \
  backup_node.postgresql.service.consul # for backwards compatibility

vault policy write issue-postgres-server-cert - <<-EOF
	path "postgrespki_int/issue/postgres-server" {
	  capabilities = ["update"]
	}
	path "postgrespki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create postgres-servers group
create_id_group "postgres-servers" \
  "issue-consul-client-cert" \
  "issue-metrics-client-cert" \
  "issue-postgres-server-cert" \
  "issue-vault-client-cert" \
  >/dev/null


# Create postgres-client role for issuing postgres client certs
create_pki_role "postgrespki_int" "postgres-client" \
  "{{identity.entity.metadata.nodename}}.global.postgres"

vault policy write issue-postgres-client-cert - <<-EOF
	path "postgrespki_int/issue/postgres-client" {
	  capabilities = ["update"]
	}
	path "postgrespki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF
