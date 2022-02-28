#!/bin/sh
# shellcheck disable=SC3043

: "${ATTL=2h}" # ttl of certs
: "${CERT_MAX_TTL=768h}"

set -e

get_mount_accessor() {
  local _mount

  _mount="$1"; shift
  vault auth list | jq -er '.["'"$_mount"'/"].accessor'
}

create_root_pki() {
  local _name _cn

  _name="$1"; shift
  _cn="$1"; shift

  vault secrets list -format=json | jq -e '.["'"$_name"'/"]' >/dev/null || \
    vault secrets enable -path "$_name" pki
  vault secrets tune -max-lease-ttl=87600h "$_name"

  vault read -format=json "$_name/cert/ca" >/dev/null || \
    vault write -format=json  -field=certificate "$_name/root/generate/internal" \
    common_name="$_cn" ttl=87600h
}

create_int_pki() {
  local _root_name _name _cn _csr _int_crt

  _root_name="$1"; shift
  _name="$1"; shift
  _cn="$1"; shift

  vault secrets list -format=json | jq -e '.["'"$_name"'/"]' >/dev/null || \
    vault secrets enable -path "$_name" pki
  vault secrets tune -max-lease-ttl=43800h "$_name"
  vault read -format=json "$_name/cert/ca" >/dev/null ||
    (
      _csr=$(vault write -format=json \
        "$_name/intermediate/generate/internal" \
        common_name="$_cn" \
        ttl="43800h" | jq -er ".data.csr")
      _int_crt=$(echo "$_csr" | \
        vault write -format=json "$_root_name/root/sign-intermediate" \
        csr=- format=pem_bundle \
        ttl="43800h" | jq -er ".data.certificate")
      echo "$_int_crt" | vault write -format=json "$_name/intermediate/set-signed" \
        certificate=-
    )

}

get_pki_ca() {
  local _name

  _name="$1"; shift
  vault read -format=json "$_name/cert/ca" | \
    jq -er ".data.certificate"
}

create_pki_role() {
  local _pki_name _name _domain _allowed_domains

  _pki_name="$1"; shift
  _name="$1"; shift
  for _domain in "$@"; do
    _allowed_domains="$_allowed_domains,$_domain"; shift
  done

  vault write -format=json "$_pki_name/roles/$_name" \
    allowed_domains="$(echo "$_allowed_domains" | tr ' ' ',' | sed 's/^,//')" \
    allowed_domains_template=true \
    allow_subdomains=false \
    ttl="$ATTL" \
    max_ttl="$CERT_MAX_TTL" \
    allow_bare_domains=true \
    allow_localhost=true \
    allow_ip_sans=true \
    require_cn=false \
    generate_lease=true
}

create_id_entity() {
  local _name _nodename _policy _policies

  _name="$1"; shift
  _nodename="$1"; shift
  for _policy in "$@"; do
    _policies="$_policies,$_policy"; shift
  done

  vault write -format=json identity/entity name="$_name" \
    metadata=nodename="$_nodename" \
    ${_policies:+policies="$(echo "$_policies" | tr ' ' ',' | sed 's/^,//')"} \
    >/dev/null
  vault read -format=json -field=id "identity/entity/name/$_name" | jq -r
}

create_id_entity_alias() {
  local _name _entity_id _mount_point _custom_metadata _accessor

  _name=$1; shift
  _entity_id="$1"; shift
  _mount_point="$1"; shift
  _custom_metadata="$1"; shift

  _accessor=$(get_mount_accessor "$_mount_point")
  vault write -format=json identity/entity-alias \
    name="$_name" \
    canonical_id="$_entity_id" \
    mount_accessor="$_accessor" \
    ${_custom_metadata:+custom_metadata="$_custom_metadata"}
}

create_id_group() {
  local _name _policy _policies

  _name="$1"; shift
  for _policy in "$@"; do
    _policies="$_policies,$_policy"; shift
  done

  vault write -format=json identity/group name="$_name" \
    ${_policies:+policies="$(echo "$_policies" | tr ' ' ',' | sed 's/^,//')"} \
    >/dev/null
  vault read -format=json -field=id "identity/group/name/$_name" | jq -r
}

add_id_group_policy() {
  local _group _name _policies

  _group="$1"; shift
  _name="$1"; shift

  _policies=$(vault read -format=json "identity/group/name/$_group" | \
    jq -re '.data.policies + ["'"$_name"'"] | sort | unique
      | join(",") | ltrimstr(",") | rtrimstr(",")')
  vault write -format=json identity/group name="$_group" \
    policies="$_policies"
}

add_id_group_member() {
  local _group _entity_id _member_ids

  _group="$1"; shift
  _entity_id="$1"; shift

  _member_ids=$(vault read -format=json "identity/group/name/$_group" | \
    jq -re '.data.member_entity_ids + ["'"$_entity_id"'"] | sort | unique
      | join(",") | ltrimstr(",") | rtrimstr(",")')
  vault write -format=json identity/group name="$_group" \
    member_entity_ids="$_member_ids"
}


#vault write -field id identity/lookup/entity alias_name=somealias \
#  alias_mount_accessor=auth_token_57bd650
#alias_id=$(vault read "identity/entity/id/$entity_id"  \
#  | jq -er \
#  '.data.aliases[] | select(.mount_accessor == "'"$accessor"'") | .id')
