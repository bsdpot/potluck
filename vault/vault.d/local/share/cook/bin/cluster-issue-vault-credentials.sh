#!/bin/sh

# environment defaults
: "${TOKEN_WRAP_TTL=10m}"

usage() {
  cat <<-EOH
	Usage: $0
	    [-a alt_name] [-c cert_ttl] [-g group] [-i ip]
	    [-e entity_suffix] [-p policy] [-t token_ttl] [-r token_role]
	    [-u issue_vault_cert_role] cert_nodename

	    token_role -- defaults to "cert-issuer"
	    vault_issue_role -- good value is"vault-client".
	    If not set, no vault client certificates will be
	    issued.

	    -e can be used to add a suffix to the entity name to
	    avoid re-using entity names

	    -a, -g, -i, -p can be specified multiple times
	    multiple comma separated entries work there too.
	EOH
}

ALT_NAMES=
CERT_TTL=
IPS=
ISSUE_ROLE=
POLICIES=
TOKEN_GROUPS=
TOKEN_ROLE=cert-issuer
TOKEN_TTL=

OPTIND=1
while getopts "ha:c:e:g:i:p:r:t:u:" _o ; do
  case "$_o" in
  h)
    usage
    exit 0
    ;;
  a)
    ALT_NAMES="$ALT_NAMES ${OPTARG}"
    ;;
  c)
    CERT_TTL="${OPTARG}"
    ;;
  e)
    ENTITY_SUFFIX="${OPTARG}"
    ;;
  g)
    TOKEN_GROUPS="$TOKEN_GROUPS ${OPTARG}"
    ;;
  i)
    IPS="$IPS ${OPTARG}"
    ;;
  p)
    POLICIES="$POLICIES $(echo "${OPTARG}" | tr ',' ' ')"
    ;;
  r)
    TOKEN_ROLE="${OPTARG}"
    ;;
  t)
    TOKEN_TTL="${OPTARG}"
    ;;
  u)
    ISSUE_ROLE="${OPTARG}"
    ;;
  *)
    2>&1 usage
    exit 1
    ;;
  esac
done

shift "$((OPTIND-1))"

if [ $# -ne 1 ]; then
  2>&1 usage
  exit 1
fi

NODENAME="$1"; shift

ENTITY_NAME="${NODENAME}${ENTITY_SUFFIX:+-$ENTITY_SUFFIX}"

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")

trap "echo \$STEP failed" EXIT

export PATH=/usr/local/bin:"$PATH"
export VAULT_ADDR=https://active.vault.service.consul:8200
export VAULT_CLIENT_CERT=/mnt/vaultcerts/agent.crt
export VAULT_CLIENT_KEY=/mnt/vaultcerts/agent.key
export VAULT_CACERT=/mnt/vaultcerts/ca_root.crt
export VAULT_FORMAT=json

STEP="Include lib"
. "${SCRIPTDIR}/lib.sh"

STEP="Create entity"
entity_id=$(create_id_entity "$ENTITY_NAME" "$NODENAME")

STEP="Create entity alias"
create_id_entity_alias "$ENTITY_NAME" "$entity_id" "token" \
  'desc="'"$ENTITY_NAME"' alias"' >/dev/null

STEP="Add entity to groups"
for group in $TOKEN_GROUPS; do
  STEP="Add entity to group $group"
  add_id_group_member "$group" "$entity_id"
done

STEP="Get Vault root CA"
CA_ROOT=$(get_pki_ca "vaultpki")

STEP="Create wrapped token"

# shellcheck disable=SC2086

POLICYPARAMS="-policy=default"
for policy in $POLICIES; do
  POLICYPARAMS="$POLICYPARAMS -policy=$policy"
done

# not super elegant to create an extra token here
TOKEN_WRAP=$(echo "$POLICYPARAMS" | tr ' ' '\0' | \
  xargs -0 vault token create \
  -display-name "$NODENAME consul-template token" \
  -role="$TOKEN_ROLE" \
  -entity-alias="$ENTITY_NAME" \
  -wrap-ttl="$TOKEN_WRAP_TTL" \
  ${TOKEN_TTL:+"-ttl=$TOKEN_TTL"} | jq -e ".wrap_info.token")

if [ -z "$ISSUE_ROLE" ]; then
  STEP="Assemble early exit response"
  echo "{
    \"wrapped_token\": $TOKEN_WRAP,
    \"ca_root\": $(echo "$CA_ROOT" | jq -sR)
  }"  | jq

  trap - EXIT
  exit 0
fi

STEP="Create issuing token"
TOKEN_ISSUE=$(echo "$POLICYPARAMS" | tr ' ' '\0' | \
  xargs -0 vault token create \
  -display-name="$NODENAME cert init token - not renewed" \
  -role="$TOKEN_ROLE" \
  -entity-alias="$ENTITY_NAME" \
  -renewable=false \
  ${TOKEN_TTL:+"-ttl=$TOKEN_TTL"} | jq -er ".auth.client_token")

STEP="Issue Vault Client Certificate"
CERT_JSON=$(VAULT_TOKEN="$TOKEN_ISSUE" \
  vault write vaultpki_int/issue/"$ISSUE_ROLE" \
  common_name="$NODENAME.global.vaultcluster" \
  ${CERT_TTL:+"-ttl=$CERT_TTL"} \
  alt_names="$(echo "$ALT_NAMES" | tr ' ' ',' | sed 's/^,//')" \
  ip_sans="$(echo "$IPS" | tr ' ' ',' | sed 's/^,//')")

STEP="Parse Vault Client Certificate"
CERT=$(echo "$CERT_JSON" | jq -e ".data.certificate")
KEY=$(echo "$CERT_JSON" | jq -e ".data.private_key")
CA=$(echo "$CERT_JSON" | jq -e ".data.issuing_ca")
CA_CHAIN=$(
  echo "$CERT_JSON" | jq -ec ".data.ca_chain[]"
)

STEP="Assemble response"
echo "{
  \"wrapped_token\": $TOKEN_WRAP,
  \"cert\": $CERT,
  \"key\": $KEY,
  \"ca\": $CA,
  \"ca_chain\": $CA_CHAIN,
  \"ca_root\": $(echo "$CA_ROOT" | jq -sR)
}"  | jq

trap - EXIT
