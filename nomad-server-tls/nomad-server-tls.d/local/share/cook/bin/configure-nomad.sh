#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

GOSSIPKEY="$(cat /mnt/nomadcerts/gossip.key)"

# This is the token that allows issuing nomad cluster token
VAULTTOKEN="$(cat /mnt/nomadcerts/unwrapped.token)"

# Get nomad consul service token
NOMAD_SERVICE_TOKEN="$(cat /mnt/nomadcerts/nomad_service.token)"

# make nomad plugin directory, may be useful in future
mkdir -p /usr/local/libexec/nomad/plugins

# Set 700 permissions on /var/tmp/nomad else nomad won't start
##chmod 700 /var/tmp/nomad
# nomad start works if no /var/tmp/nomad present
# move it aside for now, should be recreated on nomad start
if [ -d /var/tmp/nomad ];
  mv -f /var/tmp/nomad /var/tmp/oldnomad
fi

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/nomad-server.hcl.in" \
  sed "s${sep}%%datacenter%%${sep}$DATACENTER${sep}g" | \
  sed "s${sep}%%nodename%%${sep}$NODENAME${sep}g" | \
  sed "s${sep}%%ip%%${sep}$IP${sep}g" | \
  sed "s${sep}%%bootstrap%%${sep}$BOOTSTRAP${sep}g" \
  > /usr/local/etc/nomad/server.hcl

chmod 600 \
  /usr/local/etc/nomad/server.hcl
echo "s${sep}%%nomadgossipkey%%${sep}$GOSSIPKEY${sep}" | sed -i '' -f - \
  /usr/local/etc/nomad/server.hcl
echo "s${sep}%%vaulttoken%%${sep}$VAULTTOKEN${sep}" | sed -i '' -f - \
  /usr/local/etc/nomad/server.hcl
echo "s${sep}%%consultoken%%${sep}$NOMAD_SERVICE_TOKEN${sep}g" |
  sed -i '' -f - /usr/local/etc/nomad/server.hcl

# set owner and perms on _directory_ /usr/local/etc/nomad with server.hcl
chown -R nomad:wheel /usr/local/etc/nomad/

# enable nomad
service nomad enable

# set load parameter for nomad config
sysrc \
  nomad_args="-config=/usr/local/etc/nomad/server.hcl -network-interface=$IP"
sysrc nomad_debug="YES"
