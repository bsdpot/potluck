#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

mkdir -p /usr/local/etc/consul.d

# There are two different configs whether consul is a single server or 3 or 5
# The BOOTSTRAP parameter MUST be set, and the PEERS variable MUST be in the
# correct format

GOSSIPKEY="$(cat /mnt/consulcerts/gossip.key)"

case $BOOTSTRAP in
1) for_cluster="#" ;;
3|5) for_cluster="" ;;
*)
  echo "there is a problem with the BOOTSTRAP VARIABLE"
  exit 1
  ;;
esac

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%bootstrap%%${sep}$BOOTSTRAP${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%peers%%${sep}$PEERS${sep}g" | \
  sed "s${sep}%%forcluster%%${sep}$for_cluster${sep}g" \
  > /usr/local/etc/consul.d/agent.hcl

chmod 600 \
  /usr/local/etc/consul.d/agent.hcl
echo "s${sep}%%gossipkey%%${sep}$GOSSIPKEY${sep}" | sed -i '' -f - \
  /usr/local/etc/consul.d/agent.hcl

# set owner on /usr/local/etc/consul.d
chown -R consul:wheel /usr/local/etc/consul.d/
# Workaround for bug in rc.d/consul script:
# enable consul
service consul enable || true
sysrc consul_args="-advertise $IP"
sysrc consul_syslog_output_enable=YES
sysrc consul_syslog_output_priority=warn


# setup consul logs, might be redundant if not specified in agent.json above
mkdir -p /mnt/log/consul
touch /mnt/log/consul/consul.log
chown -R consul:wheel /mnt/log/consul
