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

create_root_pki "consulpki" "$DATACENTER.consul root"
create_int_pki "consulpki" "consulpki_int" "$DATACENTER.consul intermediate"

# Create consul-server role for issuing consul server certs
create_pki_role "consulpki_int" "consul-server" \
  "{{identity.entity.metadata.nodename}}.$DATACENTER.consul" \
  "server.$DATACENTER.consul"

vault policy write issue-consul-server-cert - <<-EOF
	path "consulpki_int/issue/consul-server" {
	  capabilities = ["update"]
	}
	path "consulpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create consul-servers group
create_id_group "consul-servers" \
  "issue-consul-server-cert" \
  "issue-metrics-client-cert" \
  "issue-vault-client-cert" \
  "issue-nomad-client-cert" \
  >/dev/null


# Create consul-client role for issuing consul client certs
create_pki_role "consulpki_int" "consul-client" \
  "{{identity.entity.metadata.nodename}}.$DATACENTER.consul"

vault policy write issue-consul-client-cert - <<-EOF
	path "consulpki_int/issue/consul-client" {
	  capabilities = ["update"]
	}
	path "consulpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create special consul-vault-clients group
create_id_group "consul-vault-clients" \
  "issue-consul-client-cert" \
  "issue-metrics-client-cert" \
  "issue-vault-client-cert" \
  >/dev/null
