#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

## start consul config
# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
chown consul /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

GOSSIPKEY="$(cat /mnt/consulcerts/gossip.key)"

< "$TEMPLATEPATH/consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$CONSULSERVERS${sep}g" \
  > /usr/local/etc/consul.d/agent.hcl

chmod 600 \
  /usr/local/etc/consul.d/agent.hcl
echo "s${sep}%%gossipkey%%${sep}$GOSSIPKEY${sep}" | sed -i '' -f - \
  /usr/local/etc/consul.d/agent.hcl

# set owner and perms on _directory_ /usr/local/etc/consul.d with agent.hcl
chown -R consul:wheel /usr/local/etc/consul.d/

# enable consul
service consul enable || true

# set load parameter for consul config
sysrc consul_args="-config-file=/usr/local/etc/consul.d/agent.hcl"
sysrc consul_syslog_output_priority="warn"
#sysrc consul_datadir="/var/db/consul"
#sysrc consul_group="wheel"

# setup consul logs, might be redundant if not specified in agent.hcl above
mkdir -p /mnt/log/consul
touch /mnt/log/consul/consul.log
chown -R consul:wheel /mnt/log/consul

# place acl-tokens
mkdir -p /var/db/consul
chmod 750 /var/db/consul
cp -a /mnt/consulcerts/acl-tokens.json /var/db/consul/.
chown -R consul:consul /var/db/consul
