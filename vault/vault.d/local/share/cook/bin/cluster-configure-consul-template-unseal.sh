#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:"$PATH"

SCRIPT=$(readlink -f "$0")
SCRIPTDIR=$(dirname "$SCRIPT")
TEMPLATEPATH=$SCRIPTDIR/../templates

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

TOKEN=$(/bin/cat /mnt/unsealcerts/unwrapped.token)

echo "Writing consul-template-unseal config"
mkdir -p /usr/local/etc/consul-template-unseal.d

< "$TEMPLATEPATH/cluster-consul-template-unseal.hcl.in" \
  sed "s${sep}%%unsealip%%${sep}$UNSEALIP${sep}g" \
  > /usr/local/etc/consul-template-unseal.d/consul-template-unseal.hcl
chmod 600 \
  /usr/local/etc/consul-template-unseal.d/consul-template-unseal.hcl
echo "s${sep}%%token%%${sep}$TOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/consul-template-unseal.d/consul-template-unseal.hcl

< "$TEMPLATEPATH/cluster-unseal-vault.tpl.in" \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%attl%%${sep}$ATTL${sep}g" | \
  sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
  > "/mnt/templates/unseal-vault.tpl"

echo "Enabling and starting consul-template-unseal"
sysrc consul_template_unseal_syslog_output_enable=YES
service consul-template-unseal enable
