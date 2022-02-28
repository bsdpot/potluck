#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/unseal-vault-bootstrap.hcl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/vault-bootstrap.hcl

< "$TEMPLATEPATH/unseal-vault.hcl.in" sed "s${sep}%%ip%%${sep}$IP${sep}g" \
  > /usr/local/etc/vault.hcl

# Set permission for vault.hcl, so that vault can read it
chown vault:wheel /usr/local/etc/vault.hcl
chown vault:wheel /usr/local/etc/vault-bootstrap.hcl

# set permissions on /mnt for vault data
mkdir -p /mnt/unsealcerts
mkdir -p /mnt/vault
chown -R vault:wheel /mnt/vault

service vault enable
sysrc vault_login_class=root
sysrc vault_syslog_output_enable=YES
sysrc vault_syslog_output_priority=warn
sysrc vault_config=/usr/local/etc/vault-bootstrap.hcl
