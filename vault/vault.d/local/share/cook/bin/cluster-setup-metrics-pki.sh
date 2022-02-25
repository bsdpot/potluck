#!/bin/sh

: "${ATTL=2h}" # ttl of certs
: "${BTTL=3h}" # ttl of tokens
: "${CERT_MAX_TTL=768h}"

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
#TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:$PATH
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
unset VAULT_FORMAT

. "${SCRIPTDIR}/lib.sh"

create_root_pki "metricspki" "$DATACENTER.metrics root"
create_int_pki "metricspki" "metricspki_int" "$DATACENTER.metrics intermediate"

# Create metrics-server role for issuing metrics server certs
create_pki_role "metricspki_int" "metrics-server" \
  "{{identity.entity.metadata.nodename}}.$DATACENTER.metrics" \
  "server.$DATACENTER.metrics"

vault policy write issue-metrics-server-cert - <<-EOF
	path "metricspki_int/issue/metrics-server" {
	  capabilities = ["update"]
	}
	path "metricspki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create metrics-servers group
create_id_group "metrics-servers" \
  "issue-consul-client-cert" \
  "issue-metrics-server-cert" \
  "issue-vault-client-cert" \
  >/dev/null

# Create metrics-node role for issuing metrics client certs
create_pki_role "metricspki_int" "metrics-client" \
  "{{identity.entity.metadata.nodename}}.$DATACENTER.metrics"

vault policy write issue-metrics-client-cert - <<-EOF
	path "metricspki_int/issue/metrics-client" {
	  capabilities = ["update"]
	}
	path "metricspki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF
