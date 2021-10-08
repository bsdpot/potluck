#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

mkdir -p /usr/local/etc/consul-template.d

# shellcheck disable=SC3003
# Safe(r) separator for sed
sep=$'\001'

TOKEN=$(/bin/cat /mnt/certs/unwrapped.token)
cp "$TEMPLATEPATH/consul-template.hcl.in" \
  /usr/local/etc/consul-template.d/consul-template.hcl
chmod 600 \
  /usr/local/etc/consul-template.d/consul-template.hcl
echo "s${sep}%%token%%${sep}$TOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/consul-template.d/consul-template.hcl

# attl is the shorter TTL, e.g. 10m
for name in client.crt client.key ca.crt; do
  < "$TEMPLATEPATH/$name.tpl.in" \
    sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
    sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
    sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" \
    sed "s${sep}%%attl%%${sep}$ATTL${sep}g" \
    > "/mnt/templates/$name.tpl"
done

# bttl is the longer TTL, e.g. 12m
for othername in consulagent.crt consulagent.key consulca.crt; do
  < "$TEMPLATEPATH/$othername.tpl.in" \
    sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
    sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
    sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" \
    sed "s${sep}%%bttl%%${sep}$BTTL${sep}g" \
    > "/mnt/templates/$othername.tpl"
done

sysrc consul_template_syslog_output_enable=YES
sysrc consul_template_syslog_priority="warn"
service consul-template enable
