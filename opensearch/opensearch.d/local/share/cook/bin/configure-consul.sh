#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

## start consul config
# make consul configuration directory and set permissions
mkdir -p /usr/local/etc/consul.d
chown consul /usr/local/etc/consul.d
chmod 750 /usr/local/etc/consul.d

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

#GOSSIPKEY="$(cat /mnt/consulcerts/gossip.key)"
# GOSSIPKEY is passed in as a variable

< "$TEMPLATEPATH/consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%port%%${sep}$SETPORT${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$FIXCONSULSERVERS${sep}g" \
  > /usr/local/etc/consul.d/agent.hcl

# set secure permissions
chmod 600 /usr/local/etc/consul.d/agent.hcl

# set gossip key
echo "s${sep}%%gossipkey%%${sep}$GOSSIPKEY${sep}" | sed -i '' -f - \
  /usr/local/etc/consul.d/agent.hcl

# set owner and perms on _directory_ /usr/local/etc/consul.d with agent.hcl
chown -R consul:wheel /usr/local/etc/consul.d/

# enable consul
service consul enable

# set load parameter for consul config
sysrc consul_args="-config-file=/usr/local/etc/consul.d/agent.hcl"
sysrc consul_syslog_output_priority="warn"
#sysrc consul_datadir="/var/db/consul"
#sysrc consul_group="wheel"

mkdir -p /var/db/consul
chmod 750 /var/db/consul
chown -R consul:consul /var/db/consul
mkdir -p /var/log/consul
chmod 750 /var/log/consul
chown -R consul:consul /var/log/consul
