#!/bin/sh

# shellcheck disable=SC1091
. /root/.env.cook

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH=/usr/local/bin:$PATH

echo 'server:
  do-not-query-localhost: no
  domain-insecure: "consul"
  qname-minimisation: no

#Add consul as a stub-zone
stub-zone:
  name: "consul"
  stub-addr: 127.0.0.1@8600
' >/etc/unbound/conf.d/consul.conf

service local_unbound enable || true
sysrc local_unbound_forwarders="${DNSFORWARDERS:-none}" || true
service local_unbound setup || true
service local_unbound restart || true
