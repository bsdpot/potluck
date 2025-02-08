#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

# shellcheck disable=SC2086
export PATH="/usr/local/bin:$PATH"

echo 'server:
  do-not-query-localhost: no
  domain-insecure: "consul"

#Add consul as a stub-zone
stub-zone:
  name: "consul"
  stub-addr: 127.0.0.1@8600
' >/etc/unbound/conf.d/consul.conf

# we need to enable this to allow queries
# only seems to work in conf.d dir
echo 'server:
  interface: 0.0.0.0
  access-control: 10.0.0.0/8 allow
  access-control: 127.0.0.0/8 allow
' >/etc/unbound/conf.d/server.conf

service local_unbound enable || true
sysrc local_unbound_forwarders="${DNSFORWARDERS:-none}" || true
service local_unbound setup || true
service local_unbound restart || true
