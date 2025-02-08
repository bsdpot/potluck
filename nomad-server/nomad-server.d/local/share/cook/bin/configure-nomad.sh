#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# fix /var/tmp/nomad issue
if [ -d /var/tmp/nomad ]; then
    mv -f /var/tmp/nomad /var/tmp/oldnomad
fi

# make nomad plugin directory, may be useful in future
mkdir -p /usr/local/libexec/nomad/plugins
chown -R nomad:wheel /usr/local/libexec/nomad/

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/nomad-server.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%region%%${sep}$REGION${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%bootstrap%%${sep}$BOOTSTRAP${sep}g" | \
  sed "s${sep}%%raftmultiplier%%${sep}$RAFTMULTIPLIER${sep}g" | \
  sed "s${sep}%%uiflag%%${sep}$UIFLAG${sep}g" \
  > /usr/local/etc/nomad/server.hcl

chmod 600 \
  /usr/local/etc/nomad/server.hcl
echo "s${sep}%%nomadgossipkey%%${sep}$GOSSIPKEY${sep}" | sed -i '' -f - \
  /usr/local/etc/nomad/server.hcl

# set owner and perms on _directory_ /usr/local/etc/nomad with server.hcl
chown -R nomad:wheel /usr/local/etc/nomad/

# enable nomad
service nomad enable || true

# set load parameter for nomad config
sysrc \
  nomad_args="-config=/usr/local/etc/nomad/server.hcl -data-dir=/var/tmp/nomad -network-interface=$IP"
sysrc nomad_debug="YES"
