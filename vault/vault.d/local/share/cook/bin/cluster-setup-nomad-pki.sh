#!/bin/sh

: "${ATTL=2h}" # ttl of certs
: "${CERT_MAX_TTL=768h}"

# for nomad-cluster-role(!)
: "${TOKEN_TTL=7200}" # in seconds

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_TIMEOUT=300s
export VAULT_MAX_RETRIES=5
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
unset VAULT_FORMAT

. "${SCRIPTDIR}/lib.sh"

create_root_pki "nomadpki" "global.nomad root"
create_int_pki "nomadpki" "nomadpki_int" "global.nomad intermediate"

# Create nomad-server role for issuing nomad server certs
create_pki_role "nomadpki_int" "nomad-server" \
  "{{identity.entity.metadata.nodename}}.global.nomad" \
  "server.global.nomad" \
  "metrics.global.nomad" \
  "nomad.service.consul"

vault policy write issue-nomad-server-cert - <<-EOF
	path "nomadpki_int/issue/nomad-server" {
	  capabilities = ["update"]
	}
	path "nomadpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# complex nomad-server-policy
vault policy write nomad-server-policy \
  "$TEMPLATEPATH/nomad-server-policy.hcl.in"

# Create nomad-cluster role - used by nomad servers
# to issue tokens with in-built consul-template
# **Don't overwrite if it exists** (so it can be adjusted)
vault read auth/token/roles/nomad-cluster ||
  < "$TEMPLATEPATH/nomad-cluster-role.json.in" \
    sed "s/%%token_ttl%%/$TOKEN_TTL/g" | \
    vault write auth/token/roles/nomad-cluster -

# Create nomad-servers group
create_id_group "nomad-servers-infra" \
  "issue-consul-client-cert" \
  "issue-metrics-client-cert" \
  "issue-nomad-server-cert" \
  "issue-vault-client-cert" \
  >/dev/null

# nomad-service-policy to be created
# somewhere down the line (site-specific)
create_id_group "nomad-servers" \
  "nomad-job-policy" \
  "nomad-service-policy" \
  "nomad-server-policy" \
  >/dev/null

# Create nomad-client role for issuing nomad client certs
# used on compute hosts
create_pki_role "nomadpki_int" "nomad-client" \
  "{{identity.entity.metadata.nodename}}.global.nomad" \
  "client.global.nomad" \
  "metrics.global.nomad"

vault policy write issue-nomad-client-cert - <<-EOF
	path "nomadpki_int/issue/nomad-client" {
	  capabilities = ["update"]
	}
	path "nomadpki/cert/ca" {
	  capabilities = ["read"]
	}
	EOF

# Create nomad-compute-hosts group
create_id_group "nomad-compute-hosts" \
  "issue-consul-client-cert" \
  "issue-metrics-client-cert" \
  "issue-nomad-client-cert" \
  "issue-vault-client-cert" \
  "issue-vault-computenode-cert" \
  >/dev/null

#vault read nomadpki_int/roles/nomad-cluster || vault write \
#  nomadpki_int/roles/nomad-cluster \
#  allowed_domains="global.nomad,service.consul" \
#  allow_subdomains=true max_ttl="$CERT_MAX_TTL" \
#  require_cn=false generate_lease=true

