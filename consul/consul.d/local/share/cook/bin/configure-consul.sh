#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

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

case $BOOTSTRAP in
1) for_cluster="#" ;;
3|5) for_cluster="" ;;
*)
  echo "there is a problem with the BOOTSTRAP VARIABLE"
  exit 1
  ;;
esac

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/consul-agent.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%bootstrap%%${sep}$BOOTSTRAP${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%consulservers%%${sep}$FIXCONSULSERVERS${sep}g" | \
  sed "s${sep}%%forcluster%%${sep}$for_cluster${sep}g" \
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
sysrc consul_args="-advertise $IP"
sysrc consul_syslog_output_enable=YES
sysrc consul_syslog_output_priority=warn

mkdir -p /var/db/consul
chmod 750 /var/db/consul
chown -R consul:consul /var/db/consul
mkdir -p /var/log/consul
chmod 750 /var/log/consul
chown -R consul:consul /var/log/consul
