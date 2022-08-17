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

#Add consul as a stub-zone
stub-zone:
  name: "consul"
' >/etc/unbound/conf.d/consul.conf

for ip in $(echo "$CONSULSERVERS" | tr ',', ' '); do
  ip=$(echo "$ip" | sed "s/[^0-9.]//g")
  echo "  stub-addr: $ip@8600" >>/etc/unbound/conf.d/consul.conf
done

service local_unbound enable || true
sysrc local_unbound_forwarders="${DNSFORWARDERS:-none}" || true
service local_unbound restart || true
